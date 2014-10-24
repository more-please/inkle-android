#import "AP_View.h"

#import "AP_Check.h"
#import "AP_GLBuffer.h"
#import "AP_GLProgram.h"
#import "AP_Layer.h"
#import "AP_Utils.h"
#import "NSObject+AP_KeepAlive.h"

#ifdef ANDROID
static inline CGPoint CGRectGetCenter(CGRect rect)
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}
#endif

@implementation AP_View {
    __weak AP_Window* _window;
    BOOL _needsLayout;
    BOOL _needsDisplay;

    NSMutableArray* _animatedProperties;

    NSArray* _zSortedSubviews;
    int _zSortIndex;
    int _iterating;
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
        _animatedFrameCenter = [[AP_AnimatedPoint alloc] initWithName:@"frameCenter" view:self];
        _animatedBoundsSize = [[AP_AnimatedSize alloc] initWithName:@"boundsSize" view:self];
        _animatedAnchor = [[AP_AnimatedPoint alloc] initWithName:@"anchor" view:self];
        _animatedAlpha = [[AP_AnimatedFloat alloc] initWithName:@"alpha" view:self];
        _animatedTransform = [[AP_AnimatedTransform alloc] initWithName:@"transform" view:self];
        _animatedBackgroundColor = [[AP_AnimatedVector4 alloc] initWithName:@"backgroundColor" view:self];
        AP_CHECK(_animatedProperties.count == 7, return nil);

        [_animatedBoundsOrigin setAll:CGPointZero];
        [_animatedFrameCenter setAll:CGRectGetCenter(frame)];
        [_animatedBoundsSize setAll:frame.size];
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
    r.size = _animatedBoundsSize.dest;
    return r;
}

- (CGRect) inFlightBounds
{
    CGRect r;
    r.origin = _animatedBoundsOrigin.inFlight;
    r.size = _animatedBoundsSize.inFlight;
    return r;
}

- (CGRect) frame
{
    CGPoint anchor = _animatedAnchor.dest;
    CGSize size = _animatedBoundsSize.dest;
    CGPoint center = _animatedFrameCenter.dest;

    CGRect r = {
        -anchor.x * size.width,
        -anchor.y * size.height,
        size.width,
        size.height
    };

    r = CGRectApplyAffineTransform(r, _animatedTransform.dest);

    r.origin.x += center.x;
    r.origin.y += center.y;

    // Hack: make sure negative sizes are preserved. This can happen
    // if the parent view has size 0, and it has an impact on autolayout.
    // as this affects autolayout.

    if (size.width < 0) {
        r.origin.x += r.size.width;
        r.size.width = -r.size.width;
    }
    if (size.height < 0) {
        r.origin.y += r.size.height;
        r.size.height = -r.size.height;
    }

    return r;
}

- (CGPoint) center
{
    return _animatedFrameCenter.dest;
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
    _animatedBoundsSize.dest = bounds.size;
    [self maybeAutolayout:oldBounds];
}

- (void) setFrame:(CGRect)newFrame
{
    CGRect oldFrame = self.frame;
    CGRect oldBounds = self.bounds;

    // Changing the frame's size generally doesn't make sense if there's
    // a transform. But we'll assume that if the frame is scaled, we
    // should apply the same scale to the bounds. This will do the right
    // thing if the transform is just a scale, which is usually the case.

    CGSize newBoundsSize = newFrame.size;

    if (oldFrame.size.width > 0) {
        newBoundsSize.width *= oldBounds.size.width / oldFrame.size.width;
    }
    if (oldFrame.size.height > 0) {
        newBoundsSize.height *= oldBounds.size.height / oldFrame.size.height;
    }
    _animatedBoundsSize.dest = newBoundsSize;

    // Move the anchor, assuming that the relative position within the frame
    // is the same as its relative position within the bounds -- again, only
    // true if the transform is a simple scale.

    CGPoint anchor = _animatedAnchor.dest;
    _animatedFrameCenter.dest = CGPointMake(
        newFrame.origin.x + anchor.x * newFrame.size.width,
        newFrame.origin.y + anchor.y * newFrame.size.height
    );

    [self maybeAutolayout:oldBounds];
}

- (void) setCenter:(CGPoint)center
{
    _animatedFrameCenter.dest = center;
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

+ (void) withoutAnimation:(void (^)(void))block
{
    AP_Animation* oldAnimation = [AP_AnimatedProperty currentAnimation];
    [AP_AnimatedProperty setCurrentAnimation:nil];
    block();
    [AP_AnimatedProperty setCurrentAnimation:oldAnimation];
}

//------------------------------------------------------------------------------------
#pragma mark - Hit testing & event dispatch
//------------------------------------------------------------------------------------

static inline CGAffineTransform toParent(AP_View* v) {
    CGPoint anchor = v->_animatedAnchor.dest;
    CGPoint boundsOrigin = v->_animatedBoundsOrigin.dest;
    CGPoint frameCenter = v->_animatedFrameCenter.dest;
    CGSize size = v->_animatedBoundsSize.dest;
    CGAffineTransform transform = v->_animatedTransform.dest;

    // In reverse order... (0,0) -> frameCenter
    CGAffineTransform t = CGAffineTransformMakeTranslation(frameCenter.x, frameCenter.y);

    // Transform about the frame center.
    t = CGAffineTransformConcat(transform, t);

    // Bounds center -> (0, 0)
    t = CGAffineTransformTranslate(t, -anchor.x * size.width, -anchor.y * size.height);
    
    // Bounds origin -> (0, 0)
    t = CGAffineTransformTranslate(t, -boundsOrigin.x, -boundsOrigin.y);

    return t;
}

static inline CGAffineTransform toParentInFlight(AP_View* v) {
    CGPoint anchor = v->_animatedAnchor.inFlight;
    CGPoint boundsOrigin = v->_animatedBoundsOrigin.inFlight;
    CGPoint frameCenter = v->_animatedFrameCenter.inFlight;
    CGSize size = v->_animatedBoundsSize.inFlight;
    CGAffineTransform transform = v->_animatedTransform.inFlight;

    // In reverse order... (0,0) -> frameCenter
    CGAffineTransform t = CGAffineTransformMakeTranslation(frameCenter.x, frameCenter.y);

    // Transform about the frame center.
    t = CGAffineTransformConcat(transform, t);

    // Bounds center -> (0, 0)
    t = CGAffineTransformTranslate(t, -anchor.x * size.width, -anchor.y * size.height);
    
    // Bounds origin -> (0, 0)
    t = CGAffineTransformTranslate(t, -boundsOrigin.x, -boundsOrigin.y);

    return t;
}

static inline CGAffineTransform fromParent(AP_View* v) {
    return CGAffineTransformInvert(toParent(v));
}

static inline CGAffineTransform fromParentInFlight(AP_View* v) {
    return CGAffineTransformInvert(toParentInFlight(v));
}

static inline CGAffineTransform toScreen(AP_View* v) {
    if (v) {
        return CGAffineTransformConcat(toParent(v), toScreen(v->_superview));
    } else {
        return CGAffineTransformIdentity;
    }
}

static inline CGAffineTransform toScreenInFlight(AP_View* v) {
    if (v) {
        return CGAffineTransformConcat(toParentInFlight(v), toScreenInFlight(v->_superview));
    } else {
        return CGAffineTransformIdentity;
    }
}

static inline CGAffineTransform fromScreen(AP_View* v) {
    if (v) {
        return CGAffineTransformConcat(fromScreen(v->_superview), fromParent(v));
    } else {
        return CGAffineTransformIdentity;
    }
}

static inline CGAffineTransform fromScreenInFlight(AP_View* v) {
    if (v) {
        return CGAffineTransformConcat(fromScreenInFlight(v->_superview), fromParentInFlight(v));
    } else {
        return CGAffineTransformIdentity;
    }
}

static inline CGAffineTransform viewToView(AP_View* src, AP_View* dest) {
    return CGAffineTransformConcat(toScreen(src), fromScreen(dest));
}

static inline CGAffineTransform viewToViewInFlight(AP_View* src, AP_View* dest) {
    return CGAffineTransformConcat(toScreenInFlight(src), fromScreenInFlight(dest));
}

- (CGPoint) convertPoint:(CGPoint)point fromView:(AP_View*)view
{
    return CGPointApplyAffineTransform(point, viewToView(view, self));
}

- (CGPoint) convertPoint:(CGPoint)point toView:(AP_View*)view
{
    return CGPointApplyAffineTransform(point, viewToView(self, view));
}

- (CGRect) convertRect:(CGRect)rect fromView:(AP_View *)view
{
    return CGRectApplyAffineTransform(rect, viewToView(view, self));
}

- (CGRect) convertRect:(CGRect)rect toView:(AP_View *)view
{
    return CGRectApplyAffineTransform(rect, viewToView(self, view));
}

- (CGPoint) convertInFlightPoint:(CGPoint)point fromView:(AP_View*)view
{
    return CGPointApplyAffineTransform(point, viewToViewInFlight(view, self));
}

- (CGPoint) convertInFlightPoint:(CGPoint)point toView:(AP_View*)view
{
    return CGPointApplyAffineTransform(point, viewToViewInFlight(self, view));
}

- (CGRect) convertInFlightRect:(CGRect)rect fromView:(AP_View *)view
{
    return CGRectApplyAffineTransform(rect, viewToViewInFlight(view, self));
}

- (CGRect) convertInFlightRect:(CGRect)rect toView:(AP_View *)view
{
    return CGRectApplyAffineTransform(rect, viewToViewInFlight(self, view));
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
    if (_allowSubviewHitTestOutsideBounds || [self pointInside:point withEvent:event]) {
        for (AP_View* view in [_subviews reverseObjectEnumerator]) {
            CGPoint p = CGPointApplyAffineTransform(point, fromParentInFlight(view));
            AP_View* v = [view hitTest:p withEvent:event];
            if (v) {
                return v;
            }
        }
        if ([self pointInside:point withEvent:event]) {
            return self;
        }
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

    AP_CHECK(!_superview, abort());

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
    if (_iterating) {
        _subviews = [_subviews mutableCopy];
    }
    AP_CHECK([_subviews containsObject:siblingSubview], abort());
    if ([_subviews containsObject:view]) {
        // Already have this view, just need to move it.
        [_subviews removeObject:view];
        NSInteger i = [_subviews indexOfObject:siblingSubview];
        [_subviews insertObject:view atIndex:i+1];
        [self zOrderChanged];
    } else {
        NSInteger i = [_subviews indexOfObject:siblingSubview];
        [self insertSubview:view atIndex:(i+1)];
    }
}

- (void) insertSubview:(AP_View *)view belowSubview:(AP_View*)siblingSubview
{
    if (_iterating) {
        _subviews = [_subviews mutableCopy];
    }
    AP_CHECK([_subviews containsObject:siblingSubview], abort());
    if ([_subviews containsObject:view]) {
        // Already have this view, just need to move it.
        [_subviews removeObject:view];
        NSInteger i = [_subviews indexOfObject:siblingSubview];
        [_subviews insertObject:view atIndex:i];
        [self zOrderChanged];
    } else {
        NSInteger i = [_subviews indexOfObject:siblingSubview];
        [self insertSubview:view atIndex:i];
    }
}

- (void) insertSubview:(AP_View *)view atIndex:(NSInteger)index
{
    if (_iterating) {
        _subviews = [_subviews mutableCopy];
    }
    AP_CHECK(view, abort());
    AP_CHECK(view->_superview != self, abort());

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

    AP_CHECK(index >= 0, abort());
    AP_CHECK(index <= _subviews.count, abort());
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
    if (_superview->_iterating) {
        _superview->_subviews = [_superview->_subviews mutableCopy];
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
    if (_iterating) {
        _subviews = [_subviews mutableCopy];
    }
    AP_CHECK(view, abort());
    AP_CHECK(view->_superview == self, abort());
    if ([_subviews lastObject] != view) {
        [_subviews removeObject:view];
        [_subviews addObject:view];
        [self zOrderChanged];
    }
}

- (void) sendSubviewToBack:(AP_View*)view
{
    if (_iterating) {
        _subviews = [_subviews mutableCopy];
    }
    AP_CHECK(view, abort());
    AP_CHECK(view->_superview == self, abort());
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

    ++_iterating;
    for (AP_View* v in _subviews) {
        [v visitWithBlock:block];
    }
    --_iterating;

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

    ++_iterating;
    for (AP_View* v in _subviews) {
        [v visitControllersWithBlock:block];
    }
    --_iterating;

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
    id protectSelf = self;

    ++_iterating;
    for (AP_View* view in _subviews) {
        [view layoutIfNeeded];
    }
    --_iterating;

    if (_needsLayout) {
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
        ++_iterating;
        for (AP_View* view in _subviews) {
            UIViewAutoresizing mask = view->_autoresizingMask;
            if (mask == UIViewAutoresizingNone) {
                continue;
            }

            CGSize delta = CGSizeMake(
                newBounds.size.width - oldBounds.size.width,
                newBounds.size.height - oldBounds.size.height);

            CGRect r = view.frame;

            CGFloat leftMargin = CGRectGetMinX(r) - CGRectGetMinX(oldBounds);
            CGFloat rightMargin = CGRectGetMaxX(oldBounds) - CGRectGetMaxX(r);
            CGFloat topMargin = CGRectGetMinY(r) - CGRectGetMinY(oldBounds);
            CGFloat bottomMargin = CGRectGetMaxY(oldBounds) - CGRectGetMaxY(r);
            
            CGFloat flexibleWidth = 0;
            CGFloat widthCount = 0;
            if (mask & UIViewAutoresizingFlexibleLeftMargin) {
                flexibleWidth += leftMargin;
                widthCount += 1;
            }
            if (mask & UIViewAutoresizingFlexibleRightMargin) {
                flexibleWidth += rightMargin;
                widthCount += 1;
            }
            if (mask & UIViewAutoresizingFlexibleWidth) {
                flexibleWidth += r.size.width;
                widthCount += 1;
            }

            if (fabs(flexibleWidth) > 0.01) {
                if (mask & UIViewAutoresizingFlexibleLeftMargin) {
                    r.origin.x += delta.width * (leftMargin / flexibleWidth);
                }
                if (mask & UIViewAutoresizingFlexibleWidth) {
                    r.size.width += delta.width * (r.size.width / flexibleWidth);
                }
            } else {
                if (mask & UIViewAutoresizingFlexibleLeftMargin) {
                    r.origin.x += delta.width / widthCount;
                }
                if (mask & UIViewAutoresizingFlexibleWidth) {
                    r.size.width += delta.width / widthCount;
                }
            }
            
            CGFloat flexibleHeight = 0;
            CGFloat heightCount = 0;
            if (mask & UIViewAutoresizingFlexibleTopMargin) {
                flexibleHeight += topMargin;
                heightCount += 1;
            }
            if (mask & UIViewAutoresizingFlexibleBottomMargin) {
                flexibleHeight += bottomMargin;
                heightCount += 1;
            }
            if (mask & UIViewAutoresizingFlexibleHeight) {
                flexibleHeight += r.size.height;
                heightCount += 1;
            }

            if (fabs(flexibleHeight) > 0.01) {
                if (mask & UIViewAutoresizingFlexibleTopMargin) {
                    r.origin.y += delta.height * (topMargin / flexibleHeight);
                }
                if (mask & UIViewAutoresizingFlexibleHeight) {
                    r.size.height += delta.height * (r.size.height / flexibleHeight);
                }
            } else {
                if (mask & UIViewAutoresizingFlexibleTopMargin) {
                    r.origin.y += delta.height / heightCount;
                }
                if (mask & UIViewAutoresizingFlexibleHeight) {
                    r.size.height += delta.height / heightCount;
                }
            }

            r.origin.x += newBounds.origin.x - oldBounds.origin.x;
            r.origin.y += newBounds.origin.y - oldBounds.origin.y;

            view.frame = r;
        }
        --_iterating;
    }

    [self layoutSubviews];
    _needsLayout = NO;

    if (controller) {
        [controller viewDidLayoutSubviews];
    }
}

- (CGSize) sizeThatFits:(CGSize)size
{
#if 1
    return self.bounds.size;
#else
    // It seems like the logic ought to be as follows, especially
    // to make the dice game work, but that breaks other stuff
    // like the "Review map" button... Bah!
    if (_subviews.count == 0) {
        return size;
    } else {
        CGRect r = CGRectNull;
        ++_iterating;
        for (AP_View* view in _subviews) {
            r = CGRectUnion(r, view.frameWithoutTransform);
        }
        --_iterating;
        return r.size;
    }
#endif
}

- (void) sizeToFit
{
    CGPoint oldOrigin = self.frame.origin;

    CGRect r = self.bounds;
    r.size = [self sizeThatFits:r.size];
    self.bounds = r;

    // Anchor the frame at its origin, not its center.
    r = self.frame;
    r.origin = oldOrigin;
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

- (void) setNeedsDisplay
{
    _needsDisplay = YES;
}

- (BOOL) takeNeedsDisplay
{
    BOOL result = _needsDisplay;
    _needsDisplay = NO;
    return result;
}

- (void) updateGL:(float)dt
{
}

- (void) renderWithBoundsToGL:(CGAffineTransform)boundsToGL alpha:(CGFloat)alpha
{
    static const char* kVertex = AP_SHADER(
        uniform mat3 transform;
        attribute vec2 pos;
        void main() {
            vec3 tpos = transform * vec3(pos, 1);
            gl_Position = vec4(tpos, 1);
        }
    );

    static const char* kFragment = AP_SHADER(
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
#if 0
    if ([self.window isHitTestView:self]) {
        backgroundColor.r = 1;
        backgroundColor.a = MAX(0.25, backgroundColor.a);
    }
    if ([self.window isGestureView:self]) {
        backgroundColor.b = 1;
        backgroundColor.a = MAX(0.25, backgroundColor.a);
    }
#endif
    backgroundColor.a *= alpha;
    if (backgroundColor.a > 0) {
        AP_CHECK(prog, return);
        AP_CHECK(buffer, return);

        CGRect r = self.inFlightBounds;
//        NSLog(@"Rendering background %.2f,%.2f,%.2f, origin: %.0f,%.0f size: %.0f,%.0f alpha: %.2f", backgroundColor.r, backgroundColor.g, backgroundColor.b, r.origin.x, r.origin.y, r.size.width, r.size.height, backgroundColor.a);

        float data[8] = {
            r.origin.x, r.origin.y,
            r.origin.x, r.origin.y + r.size.height,
            r.origin.x + r.size.width, r.origin.y,
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

        [buffer unbind];
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
    CGPoint frameCenter = _animatedFrameCenter.inFlight;
    CGSize size = _animatedBoundsSize.inFlight;

    CGAffineTransform boundsCenterToOrigin = CGAffineTransformMakeTranslation(
        -(boundsOrigin.x + anchor.x * size.width),
        -(boundsOrigin.y + anchor.y * size.height));

    CGAffineTransform originToFrameCenter = CGAffineTransformMakeTranslation(
        frameCenter.x, frameCenter.y);

    CGAffineTransform boundsToGL = CGAffineTransformIdentity;
    boundsToGL = CGAffineTransformConcat(boundsToGL, boundsCenterToOrigin);
    boundsToGL = CGAffineTransformConcat(boundsToGL, _animatedTransform.inFlight);
    boundsToGL = CGAffineTransformConcat(boundsToGL, originToFrameCenter);
    boundsToGL = CGAffineTransformConcat(boundsToGL, frameToGL);

    // Skip drawing if we're entirely off-screen.
    CGRect glBounds;
    glBounds.origin = boundsOrigin;
    glBounds.size = size;
    glBounds = CGRectApplyAffineTransform(glBounds, boundsToGL);
    CGRect glScreen = { -1, -1, 2, 2 };
    if (!CGRectIntersectsRect(glBounds, glScreen)) {
        return;
    }

    BOOL shouldScissor = _clipsToBounds;
    CGRect oldScissorRect;
    if (shouldScissor) {
        oldScissorRect = [AP_Window overlayScissorRect:glBounds];
    }

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

    ++_iterating;
    for (AP_View* view in _zSortedSubviews) {
        [view renderSelfAndChildrenWithFrameToGL:boundsToGL alpha:alpha];
    }
    --_iterating;

    if (shouldScissor) {
        [AP_Window setScissorRect:oldScissorRect];
    }
}

//------------------------------------------------------------------------------------
#pragma mark - Misc unimplemented
//------------------------------------------------------------------------------------

- (void) addGestureRecognizer:(AP_GestureRecognizer*)gestureRecognizer
{
    NSAssert(!gestureRecognizer.view,
        @"Tried to GestureRecognizer to view: %@, but it's already in view: %@",
        self, gestureRecognizer.view);
    // Defend against "modified during iteration" errors
    _gestureRecognizers = [_gestureRecognizers mutableCopy];
    [_gestureRecognizers addObject:gestureRecognizer];
    [gestureRecognizer wasAddedToView:self];
}

- (void) removeGestureRecognizer:(AP_GestureRecognizer*)gestureRecognizer
{
    NSAssert(gestureRecognizer.view == self,
        @"Tried to remove non-existent GestureRecognizer from view: %@", self);
    // Defend against "modified during iteration" errors
    _gestureRecognizers = [_gestureRecognizers mutableCopy];
    [_gestureRecognizers removeObject:gestureRecognizer];
    [gestureRecognizer wasAddedToView:nil];
}

@end
