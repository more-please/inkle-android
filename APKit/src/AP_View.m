#import "AP_View.h"

#import "AP_Check.h"
#import "AP_GLBuffer.h"
#import "AP_GLProgram.h"
#import "AP_Layer.h"
#import "AP_Utils.h"
#import "NSObject+AP_KeepAlive.h"

@implementation AP_View {
    AP_Window* _window;
    BOOL _needsLayout;

    NSArray* _zSortedSubviews;
    int _zSortIndex;
}

- (AP_View*) init
{
    return [self initWithFrame:CGRectMake(0, 0, 0, 0)];
}

- (AP_View*) initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        _layer = [[AP_Layer alloc] initWithView:self];
        _subviews = [NSMutableArray array];
        _gestureRecognizers = [NSMutableArray array];

        _currentProps = [[AP_AnimationProps alloc] init];
        _currentProps.frame = frame;
        _currentProps.bounds = CGRectMake(0, 0, frame.size.width, frame.size.height);

        _previousProps = [[AP_AnimationProps alloc] init];
        _previousProps.frame = frame;
        _previousProps.bounds = CGRectMake(0, 0, frame.size.width, frame.size.height);

        _inFlightProps = [[AP_AnimationProps alloc] init];
        _inFlightProps.frame = frame;
        _inFlightProps.bounds = CGRectMake(0, 0, frame.size.width, frame.size.height);

        _autoresizesSubviews = YES;
        _autoresizingMask = UIViewAutoresizingNone;
        _contentMode = UIViewContentModeScaleToFill;
        _opaque = YES;
        _hidden = NO;
        _clipsToBounds = NO;
        _userInteractionEnabled = YES;
    }
    return self;
}

- (void) dealloc
{
    NSLog(@"Deleting AP_View: %@", self);
}

//------------------------------------------------------------------------------------
#pragma mark - Animation
//------------------------------------------------------------------------------------

- (CGRect) bounds { return _currentProps.bounds; }
- (CGRect) frame { return _currentProps.frame; }
- (CGPoint) center { return _currentProps.center; }
- (CGAffineTransform) transform { return _currentProps.transform; }
- (CGFloat) alpha { return _currentProps.alpha; }
- (UIColor*) backgroundColor { return AP_VectorToColor(_currentProps.backgroundColor); }

- (void) setBounds:(CGRect)bounds
{
    CGRect oldBounds = _currentProps.bounds;
    if (![self maybeJoinActiveAnimation]) {
        [_previousProps setBounds:bounds];
    }
    [_currentProps setBounds:bounds];
    [self maybeAutolayout:oldBounds];
}

- (void) setFrame:(CGRect)frame
{
    CGRect oldBounds = _currentProps.bounds;
    if (![self maybeJoinActiveAnimation]) {
        [_previousProps setFrame:frame];
    }
    [_currentProps setFrame:frame];
    [self maybeAutolayout:oldBounds];
}

- (void) setCenter:(CGPoint)center
{
    if (![self maybeJoinActiveAnimation]) {
        [_previousProps setCenter:center];
    }
    [_currentProps setCenter:center];
}

- (void) setTransform:(CGAffineTransform)transform
{
    if (![self maybeJoinActiveAnimation]) {
        [_previousProps setTransform:transform];
    }
    [_currentProps setTransform:transform];
}

- (void) setAlpha:(CGFloat)alpha
{
    if (![self maybeJoinActiveAnimation]) {
        [_previousProps setAlpha:alpha];
    }
    [_currentProps setAlpha:alpha];
}

- (void) setBackgroundColor:(UIColor*)color
{
    GLKVector4 rgba = AP_ColorToVector(color);
    if (![self maybeJoinActiveAnimation]) {
        [_previousProps setBackgroundColor:rgba];
    }
    [_currentProps setBackgroundColor:rgba];
}

- (void) setAnimation:(AP_Animation *)animation
{
    if (_animationTrap) {
        NSLog(@"Animation trap!");
    }
    if (_animation != animation) {
        if (_animation) {
            [self finishAnimation];
        }
        _animation = animation;
        if (_animation) {
            [_animation addView:self];
        }
    }
}

- (void) cancelAnimation
{
    if (_animation) {
        [_animation cancel];
    }
}

- (void) finishAnimation
{
    if (_animation) {
        [_animation finish];
    }
}

- (void) updateAnimation
{
    if (_animation) {
        if (_animationTrap) {
            NSLog(@"Animation trap!");
        }
        [_inFlightProps lerpFrom:_previousProps to:_currentProps atTime:[_animation progress]];
    } else {
        [_previousProps copyFrom:_currentProps];
        [_inFlightProps copyFrom:_currentProps];
    }
}

- (void) animationWasCancelled
{
    [_previousProps copyFrom:_inFlightProps];
    _animation = nil;
}

- (void) animationWasFinished
{
    [_previousProps copyFrom:_currentProps];
    [_inFlightProps copyFrom:_currentProps];
    _animation = nil;
}

+ (void) animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations
{
    [AP_View animateWithDuration:duration delay:0 options:0 animations:animations completion:nil];
}

+ (void) animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL))completion
{
    [AP_View animateWithDuration:duration delay:0 options:0 animations:animations completion:completion];
}

static AP_Animation* g_ActiveAnimation = nil;

+ (void) animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL))completion
{
    AP_Animation* oldAnimation = g_ActiveAnimation;
    g_ActiveAnimation = [[AP_Animation alloc] initWithDuration:duration delay:delay options:options completion:completion];
    animations();
    g_ActiveAnimation = oldAnimation;
}

- (BOOL) maybeJoinActiveAnimation
{
    if (g_ActiveAnimation) {
        self.animation = g_ActiveAnimation;
        return YES;
    } else {
        return NO;
    }
}

+ (void) debugAnimationWithTag:(NSString *)tag
{
    AP_CHECK(g_ActiveAnimation, return);
    g_ActiveAnimation.tag = tag;
}

//------------------------------------------------------------------------------------
#pragma mark - Hit testing & event dispatch
//------------------------------------------------------------------------------------

static CGPoint convertPoint(CGPoint point, AP_View* src, AP_View* dest) {
    for (AP_View* v = dest; v; v = v->_superview) {
        CGRect bounds = v->_currentProps.bounds;
        CGRect frame = v->_currentProps.frame;
        point.x -= frame.origin.x - bounds.origin.x;
        point.y -= frame.origin.y - bounds.origin.y;
    }
    for (AP_View* v = src; v; v = v->_superview) {
        CGRect bounds = v->_currentProps.bounds;
        CGRect frame = v->_currentProps.frame;
        point.x += frame.origin.x - bounds.origin.x;
        point.y += frame.origin.y - bounds.origin.y;
    }
    return point;
}

static CGPoint convertInFlightPoint(CGPoint point, AP_View* src, AP_View* dest) {
    for (AP_View* v = dest; v; v = v->_superview) {
        CGRect bounds = v->_inFlightProps.bounds;
        CGRect frame = v->_inFlightProps.frame;
        point.x -= frame.origin.x - bounds.origin.x;
        point.y -= frame.origin.y - bounds.origin.y;
    }
    for (AP_View* v = src; v; v = v->_superview) {
        CGRect bounds = v->_inFlightProps.bounds;
        CGRect frame = v->_inFlightProps.frame;
        point.x += frame.origin.x - bounds.origin.x;
        point.y += frame.origin.y - bounds.origin.y;
    }
    return point;
}

- (CGPoint) convertPoint:(CGPoint)point fromView:(AP_View*)view
{
    return convertPoint(point, view, self);
}

- (CGPoint) convertPoint:(CGPoint)point toView:(AP_View*)view
{
    return convertPoint(point, self, view);
}

- (CGRect) convertRect:(CGRect)rect fromView:(AP_View *)view
{
    rect.origin = convertPoint(rect.origin, view, self);
    return rect;
}

- (CGRect) convertRect:(CGRect)rect toView:(AP_View *)view
{
    rect.origin = convertPoint(rect.origin, self, view);
    return rect;
}

- (CGPoint) convertInFlightPoint:(CGPoint)point fromView:(AP_View*)view
{
    return convertInFlightPoint(point, view, self);
}

- (CGPoint) convertInFlightPoint:(CGPoint)point toView:(AP_View*)view
{
    return convertInFlightPoint(point, self, view);
}

- (CGRect) convertInFlightRect:(CGRect)rect fromView:(AP_View *)view
{
    rect.origin = convertInFlightPoint(rect.origin, view, self);
    return rect;
}

- (CGRect) convertInFlightRect:(CGRect)rect toView:(AP_View *)view
{
    rect.origin = convertInFlightPoint(rect.origin, self, view);
    return rect;
}

- (AP_View*) hitTest:(CGPoint)point withEvent:(AP_Event*)event
{
    if (_hidden || _inFlightProps.alpha < 0.01) {
        return nil;
    }
    if (!self.isUserInteractionEnabled) {
        return nil;
    }
    if (self.animation && !(self.animation.options & UIViewAnimationOptionAllowUserInteraction)) {
        return nil;
    }
    if ([self pointInside:point withEvent:event]) {
        for (AP_View* view in [_subviews reverseObjectEnumerator]) {
            CGPoint p = [view convertInFlightPoint:point fromView:self];
            AP_View* v = [view hitTest:p withEvent:event];
            if (v) {
                return v;
            }
        }
        return self;
    }
    return nil;
}

- (BOOL) pointInside:(CGPoint)point withEvent:(AP_Event*)event
{
    CGRect r = _inFlightProps.bounds;
    return CGRectContainsPoint(r, point);
}

- (AP_Responder*) nextResponder
{
    AP_ViewController* controller = _viewDelegate;
    if (controller) {
        return controller;
    }
    if (_superview) {
        return _superview;
    }
    return nil;
}

//------------------------------------------------------------------------------------
#pragma mark - View & window hierarchy
//------------------------------------------------------------------------------------

- (AP_View*) viewWithTag:(NSInteger)tag
{
    for (AP_View* v in _subviews) {
        AP_View* result = [v viewWithTag:tag];
        if (result) {
            return result;
        }
    }
    if (_tag == tag) {
        return self;
    }
    return nil;
}

- (AP_Window*) window
{
    if (_window) {
        return _window;
    } else if (_superview) {
        return _superview.window;
    } else {
        return nil;
    }
}

- (void) setWindow:(AP_Window *)window
{
    AP_CHECK(!_superview, return);

    AP_Window* oldWindow = self.window;
    if (!oldWindow && window) {
        [self visitControllersWithBlock:^(AP_ViewController* vc){
            [vc viewWillAppear:NO];
        }];
    }
    if (oldWindow && !window) {
        if (_animation) {
            [_animation removeView:self];
        }
        [self visitControllersWithBlock:^(AP_ViewController* vc){
            [vc viewWillDisappear:NO];
        }];
    }

    [self willMoveToWindow:window];

    _window = window;

    [self didMoveToWindow];

    if (!oldWindow && window) {
        [self visitControllersWithBlock:^(AP_ViewController* vc){
            [vc viewDidAppear:NO];
        }];
    }
    if (oldWindow && !window) {
        [self visitControllersWithBlock:^(AP_ViewController* vc){
            [vc viewDidDisappear:NO];
        }];
    }
}

- (void) addSubview:(AP_View*)view
{
    if ([_subviews containsObject:view]) {
        [self bringSubviewToFront:view];
    } else {
        [self insertSubview:view atIndex:[_subviews count]];
    }
}

- (void) insertSubview:(AP_View *)view aboveSubview:(AP_View*)siblingSubview
{
    NSInteger i = [_subviews indexOfObject:siblingSubview];
    AP_CHECK(i != NSNotFound, return);
    [self insertSubview:view atIndex:(i+1)];
}

- (void) insertSubview:(AP_View *)view belowSubview:(AP_View*)siblingSubview
{
    NSInteger i = [_subviews indexOfObject:siblingSubview];
    AP_CHECK(i != NSNotFound, return);
    [self insertSubview:view atIndex:i];
}

- (void) insertSubview:(AP_View *)view atIndex:(NSInteger)index
{
    AP_CHECK(view, return);
    AP_CHECK(view->_superview != self, return);

    AP_Window* oldWindow = view.window;
    AP_Window* newWindow = self.window;
    BOOL willChangeWindow = newWindow != oldWindow;
    BOOL willAppear = willChangeWindow && !oldWindow;

    if (willAppear) {
        [view visitControllersWithBlock:^(AP_ViewController* vc){
            [vc viewWillAppear:NO];
        }];
    }

    if (willChangeWindow) {
        [view willMoveToWindow:newWindow];
    }

    [view willMoveToSuperview:self];

    AP_View* superview = view->_superview;
    if (superview) {
        [superview willRemoveSubview:view];
        [superview->_subviews removeObject:view];
        [superview zOrderChanged];
        view->_superview = nil;
    }

    AP_CHECK(index >= 0, return);
    AP_CHECK(index <= _subviews.count, return);
    [_subviews insertObject:view atIndex:index];
    [self zOrderChanged];

    view->_superview = self;
    view->_window = nil;

    [self didAddSubview:view];
    [self setNeedsLayout];
    [view didMoveToSuperview];

    if (willChangeWindow) {
        [view didMoveToWindow];
    }
    
    if (willAppear) {
        [view visitControllersWithBlock:^(AP_ViewController* vc){
            [vc viewDidAppear:NO];
        }];
    }
}

- (void) removeFromSuperview
{
    if (!_superview) {
        return;
    }

    BOOL willDisappear = (self.window != nil);
    if (willDisappear) {
        if (_animation) {
            [_animation removeView:self];
        }
        [self visitControllersWithBlock:^(AP_ViewController* vc){
            [vc viewWillDisappear:NO];
        }];
        [self willMoveToWindow:nil];
    }

    [self willMoveToSuperview:nil];
    [_superview willRemoveSubview:self];
    [_superview setNeedsLayout];

    [_superview->_subviews removeObject:self];
    [_superview zOrderChanged];
    _superview = nil;
    _window = nil;

    [self didMoveToSuperview];

    if (willDisappear) {
        [self didMoveToWindow];
        [self visitControllersWithBlock:^(AP_ViewController* vc){
            [vc viewDidDisappear:NO];
        }];
    }
}

- (void) bringSubviewToFront:(AP_View*)view
{
    AP_CHECK(view, return);
    AP_CHECK(view->_superview == self, return);
    if ([_subviews lastObject] != view) {
        [_subviews removeObject:view];
        [_subviews addObject:view];
        [self zOrderChanged];
    }
}

- (void) sendSubviewToBack:(AP_View*)view
{
    AP_CHECK(view, return);
    AP_CHECK(view->_superview == self, return);
    if ([_subviews objectAtIndex:0] != view) {
        [_subviews removeObject:view];
        [_subviews insertObject:view atIndex:0];
        [self zOrderChanged];
    }
}

- (void) visitWithBlock:(void(^)(AP_View*))block
{
    AP_CHECK(block, return);
    NSArray* subviews = [_subviews mutableCopy];
    block(self);
    for (AP_View* v in subviews) {
        [v visitWithBlock:block];
    }
}

- (void) visitControllersWithBlock:(void(^)(AP_ViewController*))block
{
    AP_CHECK(block, return);
    NSArray* subviews = [_subviews mutableCopy];
    AP_ViewController* controller = _viewDelegate;
    if (controller) {
        block(controller);
    }
    for (AP_View* v in subviews) {
        [v visitControllersWithBlock:block];
    }
}

//------------------------------------------------------------------------------------
#pragma mark - Layout
//------------------------------------------------------------------------------------

- (void) setNeedsLayout
{
    _needsLayout = YES;
}

- (void) layoutIfNeeded
{
    AP_View* view = self;
    while (view->_superview && view->_superview->_needsLayout) {
        view = view->_superview;
    }
    if (view->_needsLayout) {
        [view layoutSelfAndChildren];
    }
}

- (void) layoutSelfAndChildren
{
    for (AP_View* view in _subviews.copy) {
        [view layoutSelfAndChildren];
    }

    AP_ViewController* controller = _viewDelegate;
    if (controller) {
        [controller viewWillLayoutSubviews];
    }

    [self layoutSubviews];
    _needsLayout = NO;

    if (controller) {
        [controller viewDidLayoutSubviews];
    }
}

- (void) maybeAutolayout:(CGRect)oldBounds
{
    CGRect newBounds = self.bounds;
    if (CGRectEqualToRect(oldBounds, newBounds)) {
        return;
    }
    AP_ViewController* controller = _viewDelegate;
    if (controller) {
        [controller viewWillLayoutSubviews];
    }
    if (_autoresizesSubviews) {
        for (AP_View* view in _subviews) {
            UIViewAutoresizing mask = view->_autoresizingMask;
            if (mask == UIViewAutoresizingNone) {
                continue;
            }

            CGRect r = view.frame;

            CGFloat leftMargin = CGRectGetMinX(r) - CGRectGetMinX(oldBounds);
            CGFloat rightMargin = CGRectGetMaxX(oldBounds) - CGRectGetMaxX(r);
            CGFloat topMargin = CGRectGetMinY(r) - CGRectGetMinY(oldBounds);
            CGFloat bottomMargin = CGRectGetMaxY(oldBounds) - CGRectGetMaxY(r);
            
            CGFloat widthFactor = 0;
            CGFloat heightFactor = 0;
            if (mask & UIViewAutoresizingFlexibleLeftMargin) {
                widthFactor += leftMargin;
            }
            if (mask & UIViewAutoresizingFlexibleRightMargin) {
                widthFactor += rightMargin;
            }
            if (mask & UIViewAutoresizingFlexibleTopMargin) {
                heightFactor += topMargin;
            }
            if (mask & UIViewAutoresizingFlexibleBottomMargin) {
                heightFactor += bottomMargin;
            }
            if (mask & UIViewAutoresizingFlexibleWidth) {
                widthFactor += r.size.width;
            }
            if (mask & UIViewAutoresizingFlexibleHeight) {
                heightFactor += r.size.height;
            }

            CGSize delta = CGSizeMake(
                newBounds.size.width - oldBounds.size.width,
                newBounds.size.height - oldBounds.size.height);

            if (widthFactor > 0) {
                if (mask & UIViewAutoresizingFlexibleLeftMargin) {
                    r.origin.x += delta.width * (leftMargin / widthFactor);
                }
                if (mask & UIViewAutoresizingFlexibleWidth) {
                    r.size.width += delta.width * (r.size.width / widthFactor);
                }
            } else if (mask & UIViewAutoresizingFlexibleWidth) {
                r.size.width += delta.width;
            } else if (mask & UIViewAutoresizingFlexibleLeftMargin) {
                r.origin.x += delta.width;
            }
            
            if (heightFactor > 0) {
                if (mask & UIViewAutoresizingFlexibleTopMargin) {
                    r.origin.y += delta.height * (topMargin / heightFactor);
                }
                if (mask & UIViewAutoresizingFlexibleHeight) {
                    r.size.height += delta.height * (r.size.height / heightFactor);
                }
            } else if (mask & UIViewAutoresizingFlexibleHeight) {
                r.size.height += delta.height;
            } else if (mask & UIViewAutoresizingFlexibleTopMargin) {
                r.origin.y += delta.height;
            }

            r.origin.x += newBounds.origin.x - oldBounds.origin.x;
            r.origin.y += newBounds.origin.y - oldBounds.origin.y;

            view.frame = r;
        }
    }

    [self layoutSubviews];
    _needsLayout = NO;

    if (controller) {
        [controller viewDidLayoutSubviews];
    }
}

- (CGSize) sizeThatFits:(CGSize)size
{
    return self.frame.size;
}

- (void) sizeToFit
{
    CGRect r = self.frame;
    r.size = [self sizeThatFits:r.size];
    self.frame = r;
}

//------------------------------------------------------------------------------------
#pragma mark - Notifications of view hierarchy changes
//------------------------------------------------------------------------------------

- (void) willRemoveSubview:(AP_View*)subview {}
- (void) didAddSubview:(AP_View*)subview {}

- (void) willMoveToSuperview:(AP_View*)newSuperview {}
- (void) didMoveToSuperview {}

- (void) willMoveToWindow:(AP_Window*)newWindow {}
- (void) didMoveToWindow {}

- (void) layoutSubviews {}

//------------------------------------------------------------------------------------
#pragma mark - Rendering
//------------------------------------------------------------------------------------

#define MULTILINE(...) #__VA_ARGS__

- (void) updateGL
{
    [self layoutIfNeeded];
}

- (void) renderWithBoundsToGL:(CGAffineTransform)boundsToGL alpha:(CGFloat)alpha
{
    static const char* kVertex = MULTILINE(
        precision highp float;
        uniform mat3 transform;
        attribute vec2 pos;
        void main() {
            vec3 tpos = transform * vec3(pos, 1);
            gl_Position = vec4(tpos, 1);
        }
    );

    static const char* kFragment = MULTILINE(
        precision highp float;
        uniform vec4 color;
        void main() {
            gl_FragColor = color;
        }
    );

    static AP_GLProgram* prog;
    static AP_GLBuffer* buffer;
    static GLint transform;
    static GLint pos;
    static GLint color;

    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        prog = [[AP_GLProgram alloc] initWithVertex:kVertex fragment:kFragment];
        buffer = [[AP_GLBuffer alloc] init];
        transform = [prog uniform:@"transform"];
        pos = [prog attr:@"pos"];
        color = [prog uniform:@"color"];
    }

    GLKVector4 backgroundColor = _inFlightProps.backgroundColor;
    static BOOL s_debugViewBorders = NO;
    if (s_debugViewBorders) {
        // Highlight all views in red, for debugging...
        backgroundColor = GLKVector4Make(1, 0, 0, 0.1);
    }
    backgroundColor.a *= alpha;
    if (backgroundColor.a > 0) {
        AP_CHECK(prog, return);
        AP_CHECK(buffer, return);

        CGRect r = _inFlightProps.bounds;
//        NSLog(@"Rendering background %.2f,%.2f,%.2f, origin: %.0f,%.0f size: %.0f,%.0f alpha: %.2f", backgroundColor.r, backgroundColor.g, backgroundColor.b, r.origin.x, r.origin.y, r.size.width, r.size.height, backgroundColor.a);

        float data[8] = {
            r.origin.x, r.origin.y,
            r.origin.x + r.size.width, r.origin.y,
            r.origin.x, r.origin.y + r.size.height,
            r.origin.x + r.size.width, r.origin.y + r.size.height
        };
        [buffer bind];
        [buffer bufferTarget:GL_ARRAY_BUFFER usage:GL_DYNAMIC_DRAW data:data size:sizeof(data)];

        GLKMatrix3 matrix = GLKMatrix3Make(
            boundsToGL.a, boundsToGL.b, 0,
            boundsToGL.c, boundsToGL.d, 0,
            boundsToGL.tx, boundsToGL.ty, 1);

        [prog use];
        glUniform4fv(color, 1, backgroundColor.v);
        glUniformMatrix3fv(transform, 1, false, matrix.m);
        glEnableVertexAttribArray(pos);
        glVertexAttribPointer(pos, 2, GL_FLOAT, false, 0, 0);

        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
}

- (void) zOrderChanged
{
    _zSortedSubviews = nil;
}

- (NSComparisonResult) zCompare:(AP_View*)other
{
    float z = _layer.zPosition;
    float zOther = other->_layer.zPosition;
    int i = _zSortIndex;
    int iOther = other->_zSortIndex;
    if (z < zOther) {
        return NSOrderedAscending;
    } else if (z > zOther) {
        return NSOrderedDescending;
    } else if (i < iOther) {
        return NSOrderedAscending;
    } else if (i > iOther) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (void) renderSelfAndChildrenWithFrameToGL:(CGAffineTransform)frameToGL alpha:(CGFloat)alpha
{
    // Update inFlightProps, if necessary.
    [self updateAnimation];

    // Build a transform that takes a point in bounds coordinates, and:
    // - moves bounds.center to (0,0)
    // - applies self.transform
    // - moves (0,0) to frame.center
    // - applies frameToGL

    if (alpha < 1 && _inFlightProps.alpha < 1) {
//        AP_LogError("Warning - incorrect alpha compositing!");
        // TODO: If this is a problem, we may have to render the parent view to a framebuffer.
    }

    alpha *= _inFlightProps.alpha;
    if (_hidden || alpha <= 0) {
        return;
    }

    CGPoint anchor = _inFlightProps.anchorPoint;
    CGRect bounds = _inFlightProps.bounds;
    CGRect frame = _inFlightProps.frame;

    CGAffineTransform boundsCenterToOrigin = CGAffineTransformMakeTranslation(
        -(bounds.origin.x + anchor.x * bounds.size.width),
        -(bounds.origin.y + anchor.y * bounds.size.height));

    CGAffineTransform originToFrameCenter = CGAffineTransformMakeTranslation(
        (frame.origin.x + anchor.x * frame.size.width),
        (frame.origin.y + anchor.y * frame.size.height));

    CGAffineTransform boundsToGL = CGAffineTransformIdentity;
    boundsToGL = CGAffineTransformConcat(boundsToGL, boundsCenterToOrigin);
    boundsToGL = CGAffineTransformConcat(boundsToGL, _inFlightProps.transform);
    boundsToGL = CGAffineTransformConcat(boundsToGL, originToFrameCenter);
    boundsToGL = CGAffineTransformConcat(boundsToGL, frameToGL);

    [self renderWithBoundsToGL:boundsToGL alpha:alpha];

    if (_zSortedSubviews) {
        // Sanity check
        AP_CHECK(_zSortedSubviews.count == _subviews.count, _zSortedSubviews = nil);
    }

    if (!_zSortedSubviews) {
        // Rebuild z-ordered subview list
        int i = 0;
        for (AP_View* view in _subviews) {
            view->_zSortIndex = i++;
        }
        _zSortedSubviews = [_subviews sortedArrayUsingSelector:@selector(zCompare:)];
    }

    for (AP_View* view in _zSortedSubviews) {
        [view renderSelfAndChildrenWithFrameToGL:boundsToGL alpha:alpha];
    }
}

//------------------------------------------------------------------------------------
#pragma mark - Misc unimplemented
//------------------------------------------------------------------------------------

- (void) addGestureRecognizer:(AP_GestureRecognizer*)gestureRecognizer
{
    [_gestureRecognizers addObject:gestureRecognizer];
    [gestureRecognizer wasAddedToView:self];
}

- (void) setNeedsDisplay
{
    AP_NOT_IMPLEMENTED;
}

@end
