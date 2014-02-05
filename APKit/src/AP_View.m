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

    NSMutableArray* _animatedProperties;

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
        _animatedProperties = [NSMutableArray array];

        _animatedBoundsOrigin = [[AP_AnimatedPoint alloc] initWithName:@"boundsOrigin" view:self];
        _animatedFrameOrigin = [[AP_AnimatedPoint alloc] initWithName:@"frameOrigin" view:self];
        _animatedSize = [[AP_AnimatedSize alloc] initWithName:@"size" view:self];
        _animatedAnchor = [[AP_AnimatedPoint alloc] initWithName:@"anchor" view:self];
        _animatedAlpha = [[AP_AnimatedFloat alloc] initWithName:@"alpha" view:self];
        _animatedTransform = [[AP_AnimatedTransform alloc] initWithName:@"transform" view:self];
        _animatedBackgroundColor = [[AP_AnimatedVector4 alloc] initWithName:@"backgroundColor" view:self];
        AP_CHECK(_animatedProperties.count == 7, return nil);

        [_animatedBoundsOrigin setAll:CGPointZero];
        [_animatedFrameOrigin setAll:frame.origin];
        [_animatedSize setAll:frame.size];
        [_animatedAnchor setAll:CGPointMake(0.5, 0.5)];
        [_animatedAlpha setAll:1];
        [_animatedTransform setAll:CGAffineTransformIdentity];
        [_animatedBackgroundColor setAll:GLKVector4Make(0, 0, 0, 0)];

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

- (void) animatedPropertyWasAdded:(AP_AnimatedProperty*)prop
{
    [_animatedProperties addObject:prop];
}

//------------------------------------------------------------------------------------
#pragma mark - Animation
//------------------------------------------------------------------------------------

- (CGRect) bounds
{
    CGRect r;
    r.origin = _animatedBoundsOrigin.dest;
    r.size = _animatedSize.dest;
    return r;
}

- (CGRect) inFlightBounds
{
    CGRect r;
    r.origin = _animatedBoundsOrigin.inFlight;
    r.size = _animatedSize.inFlight;
    return r;
}

- (CGRect) frame
{
    CGRect r;
    r.origin = _animatedFrameOrigin.dest;
    r.size = _animatedSize.dest;
    return r;
}

- (CGPoint) center
{
    CGPoint anchor = _animatedAnchor.dest;
    CGPoint origin = _animatedFrameOrigin.dest;
    CGSize size = _animatedSize.dest;
    return CGPointMake(
        origin.x + size.width * anchor.x,
        origin.y + size.height * anchor.y);
}

- (CGAffineTransform) transform
{
    return _animatedTransform.dest;
}

- (CGFloat) alpha
{
    return _animatedAlpha.dest;
}

- (UIColor*) backgroundColor
{
    return AP_VectorToColor(_animatedBackgroundColor.dest);
}

- (void) setBounds:(CGRect)bounds
{
    CGRect oldBounds = self.bounds;
    _animatedBoundsOrigin.dest = bounds.origin;
    _animatedSize.dest = bounds.size;
    [self maybeAutolayout:oldBounds];
}

- (void) setFrame:(CGRect)frame
{
    CGRect oldBounds = self.bounds;
    _animatedFrameOrigin.dest = frame.origin;
    _animatedSize.dest = frame.size;
    [self maybeAutolayout:oldBounds];
}

- (void) setCenter:(CGPoint)center
{
    CGPoint oldCenter = self.center;
    CGPoint origin = _animatedFrameOrigin.dest;
    origin.x += (center.x - oldCenter.x);
    origin.y += (center.y - oldCenter.y);
    _animatedFrameOrigin.dest = origin;
}

- (void) setTransform:(CGAffineTransform)transform
{
    _animatedTransform.dest = transform;
}

- (void) setAlpha:(CGFloat)alpha
{
    _animatedAlpha.dest = alpha;
}

- (void) setBackgroundColor:(UIColor*)color
{
    _animatedBackgroundColor.dest = AP_ColorToVector(color);
}

+ (void) animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations
{
    [AP_View animateWithDuration:duration delay:0 options:0 animations:animations completion:nil];
}

+ (void) animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL))completion
{
    [AP_View animateWithDuration:duration delay:0 options:0 animations:animations completion:completion];
}

+ (void) animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL))completion
{
    AP_Animation* animation = [[AP_Animation alloc] initWithDuration:duration delay:delay options:options completion:completion];

    AP_Animation* oldAnimation = [AP_AnimatedProperty currentAnimation];
    [AP_AnimatedProperty setCurrentAnimation:animation];
    animations();
    [AP_AnimatedProperty setCurrentAnimation:oldAnimation];
}

+ (void) debugAnimationWithTag:(NSString*)tag
{
    [AP_AnimatedProperty currentAnimation].tag = tag;
}

//------------------------------------------------------------------------------------
#pragma mark - Hit testing & event dispatch
//------------------------------------------------------------------------------------

static CGPoint convertPoint(CGPoint point, AP_View* src, AP_View* dest) {
    for (AP_View* v = dest; v; v = v->_superview) {
        CGPoint boundsOrigin = v->_animatedBoundsOrigin.dest;
        CGPoint frameOrigin = v->_animatedFrameOrigin.dest;
        point.x -= frameOrigin.x - boundsOrigin.x;
        point.y -= frameOrigin.y - boundsOrigin.y;
    }
    for (AP_View* v = src; v; v = v->_superview) {
        CGPoint boundsOrigin = v->_animatedBoundsOrigin.dest;
        CGPoint frameOrigin = v->_animatedFrameOrigin.dest;
        point.x += frameOrigin.x - boundsOrigin.x;
        point.y += frameOrigin.y - boundsOrigin.y;
    }
    return point;
}

static CGPoint convertInFlightPoint(CGPoint point, AP_View* src, AP_View* dest) {
    for (AP_View* v = dest; v; v = v->_superview) {
        CGPoint boundsOrigin = v->_animatedBoundsOrigin.inFlight;
        CGPoint frameOrigin = v->_animatedFrameOrigin.inFlight;
        point.x -= frameOrigin.x - boundsOrigin.x;
        point.y -= frameOrigin.y - boundsOrigin.y;
    }
    for (AP_View* v = src; v; v = v->_superview) {
        CGPoint boundsOrigin = v->_animatedBoundsOrigin.inFlight;
        CGPoint frameOrigin = v->_animatedFrameOrigin.inFlight;
        point.x += frameOrigin.x - boundsOrigin.x;
        point.y += frameOrigin.y - boundsOrigin.y;
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
    if (_hidden || _animatedAlpha.inFlight < 0.01) {
        return nil;
    }
    if (!self.isUserInteractionEnabled) {
        return nil;
    }
    for (AP_AnimatedProperty* prop in _animatedProperties) {
        AP_Animation* a = prop.animation;
        if (a && !(a.options & UIViewAnimationOptionAllowUserInteraction)) {
            return nil;
        }
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
    CGRect r = self.inFlightBounds;
    return CGRectContainsPoint(r, point);
}

- (AP_Responder*) nextResponder
{
    AP_ViewController* controller = _viewDelegate;
    if (controller) {
        return controller;
    }
    AP_View* superview = _superview;
    if (superview) {
        return superview;
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
    id protectSelf = self;

    AP_CHECK(!_superview, return);

    AP_Window* oldWindow = self.window;
    if (!oldWindow && window) {
        [self visitControllersWithBlock:^(AP_ViewController* vc){
            [vc viewWillAppear:NO];
        }];
    }
    if (oldWindow && !window) {
        for (AP_AnimatedProperty* prop in _animatedProperties) {
            [prop leaveAnimation];
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

    [protectSelf self];
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

    id protectSelf = self;

    BOOL willDisappear = (self.window != nil);
    if (willDisappear) {
        for (AP_AnimatedProperty* prop in _animatedProperties) {
            [prop leaveAnimation];
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

    [protectSelf self];
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
    id protectSelf = self;
    AP_CHECK(block, return);
    block(self);
    for (AP_View* v in _subviews) {
        [v visitWithBlock:block];
    }
    [protectSelf self];
}

- (void) visitControllersWithBlock:(void(^)(AP_ViewController*))block
{
    id protectSelf = self;
    AP_CHECK(block, return);
    AP_ViewController* controller = _viewDelegate;
    if (controller) {
        block(controller);
    }
    for (AP_View* v in _subviews) {
        [v visitControllersWithBlock:block];
    }
    [protectSelf self];
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
    AP_View* superview = view->_superview;
    while (superview && superview->_needsLayout) {
        view = superview;
        superview = view->_superview;
    }
    if (view->_needsLayout) {
        [view layoutSelfAndChildren];
    }
}

- (void) layoutSelfAndChildren
{
    id protectSelf = self;

    for (AP_View* view in _subviews) {
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

    [protectSelf self];
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

            if (fabs(widthFactor) > 1e-6) {
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
            
            if (fabs(heightFactor) > 1e-6) {
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

    GLKVector4 backgroundColor = _animatedBackgroundColor.inFlight;
    static BOOL s_debugViewBorders = NO;
    if (s_debugViewBorders) {
        // Highlight all views in red, for debugging...
        backgroundColor = GLKVector4Make(1, 0, 0, 0.1);
    }
    backgroundColor.a *= alpha;
    if (backgroundColor.a > 0) {
        AP_CHECK(prog, return);
        AP_CHECK(buffer, return);

        CGRect r = self.inFlightBounds;
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
    // Build a transform that takes a point in bounds coordinates, and:
    // - moves bounds.center to (0,0)
    // - applies self.transform
    // - moves (0,0) to frame.center
    // - applies frameToGL

    if (alpha < 1 && _animatedAlpha.inFlight < 1) {
//        AP_LogError("Warning - incorrect alpha compositing!");
        // TODO: If this is a problem, we may have to render the parent view to a framebuffer.
    }

    alpha *= _animatedAlpha.inFlight;
    if (_hidden || alpha <= 0) {
        return;
    }

    CGPoint anchor = _animatedAnchor.inFlight;
    CGPoint boundsOrigin = _animatedBoundsOrigin.inFlight;
    CGPoint frameOrigin = _animatedFrameOrigin.inFlight;
    CGSize size = _animatedSize.inFlight;

    CGAffineTransform boundsCenterToOrigin = CGAffineTransformMakeTranslation(
        -(boundsOrigin.x + anchor.x * size.width),
        -(boundsOrigin.y + anchor.y * size.height));

    CGAffineTransform originToFrameCenter = CGAffineTransformMakeTranslation(
        (frameOrigin.x + anchor.x * size.width),
        (frameOrigin.y + anchor.y * size.height));

    CGAffineTransform boundsToGL = CGAffineTransformIdentity;
    boundsToGL = CGAffineTransformConcat(boundsToGL, boundsCenterToOrigin);
    boundsToGL = CGAffineTransformConcat(boundsToGL, _animatedTransform.inFlight);
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
