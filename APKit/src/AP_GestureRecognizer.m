#import "AP_GestureRecognizer.h"

#import "AP_Check.h"
#import "AP_Touch.h"

@implementation AP_GestureRecognizer {
    __weak id _target;
    SEL _action;
    IMP _imp;
    int _numArgs;
}

- (id) initWithTarget:(id)target action:(SEL)action
{
    AP_CHECK(target, return nil);
    self = [super init];
    if (self) {
        _target = target;
        _action = action;
        _imp = [target methodForSelector:action];
        _numArgs = [target methodSignatureForSelector:action].numberOfArguments;
        AP_CHECK(_numArgs <= 3, return nil);

        _enabled = YES;
        _state = UIGestureRecognizerStatePossible;
    }
    return self;
}

- (void) wasAddedToView:(AP_View*)view
{
    AP_CHECK(!_view, _view = nil);
    _view = view;
}

- (void) fireWithState:(UIGestureRecognizerState)state
{
    _state = state;
    AP_CHECK(_state != UIGestureRecognizerStatePossible, return);
    if (_numArgs == 2) {
        void (*func)(id, SEL) = (void*) _imp;
        func(_target, _action);
    } else {
        AP_CHECK(_numArgs == 3, return);
        void (*func)(id, SEL, id) = (void*) _imp;
        func(_target, _action, self);
    }
}

- (void) touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event {}
- (void) touchesMoved:(NSSet*)touches withEvent:(AP_Event*)event {}
- (void) touchesEnded:(NSSet*)touches withEvent:(AP_Event*)event {}
- (void) touchesCancelled:(NSSet*)touches withEvent:(AP_Event*)event {}
- (void) reset
{
    _state = UIGestureRecognizerStatePossible;
}

- (CGPoint) locationInView:(AP_View*)view
{
    AP_NOT_IMPLEMENTED;
    return CGPointZero;
}

- (NSUInteger) numberOfTouches
{
    AP_NOT_IMPLEMENTED;
    return 0;
}

@end

@implementation AP_TapGestureRecognizer
@end

@implementation AP_LongPressGestureRecognizer
@end

@implementation AP_PinchGestureRecognizer {
    NSMutableSet* _touches;
}

- (NSUInteger) numberOfTouches
{
    return _touches.count;
}

- (void) touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event
{
    if (!_touches && event.allTouches.count == 2) {
        _touches = [NSMutableSet setWithSet:event.allTouches];
        [self fireWithState:UIGestureRecognizerStateBegan];
    }
}

- (void) touchesMoved:(NSSet*)touches withEvent:(AP_Event*)event
{
    for (AP_Touch* t in _touches) {
        if (t.phase == UITouchPhaseMoved) {
            [self fireWithState:UIGestureRecognizerStateChanged];
            return;
        }
    }
}

- (void) touchesEnded:(NSSet*)touches withEvent:(AP_Event*)event
{
    if (_touches) {
        [_touches minusSet:touches];
        if ([_touches count] < 2) {
            [self fireWithState:UIGestureRecognizerStateEnded];
            [self reset];
        }
    }
}

- (void) touchesCancelled:(NSSet*)touches withEvent:(AP_Event*)event
{
    if (_touches) {
        [_touches minusSet:touches];
        if ([_touches count] == 0) {
            [self fireWithState:UIGestureRecognizerStateCancelled];
            [self reset];
        }
    }
}

- (void) reset
{
    _touches = nil;
    [super reset];
}

static inline CGFloat distance(CGPoint a, CGPoint b) {
    CGPoint p = {a.x - b.x, a.y - b.y};
    return sqrtf(p.x * p.x + p.y * p.y);
}

- (CGFloat)scale
{
    if (!_touches || _touches.count != 2) {
        return 1;
    }
    AP_Touch* pinch[2];
    int i = 0;
    for (AP_Touch* t in _touches) {
        pinch[i++] = t;
    }
    CGFloat d0 = distance(pinch[0].initialWindowPos, pinch[1].initialWindowPos);
    CGFloat d1 = distance(pinch[0].windowPos, pinch[1].windowPos);
    if (d0 <= 0) {
        return 1;
    } else {
        return d1 / d0;
    }
}

- (CGFloat) velocity
{
    AP_NOT_IMPLEMENTED;
    return 0;
}

@end

@implementation AP_PanGestureRecognizer {
    NSMutableSet* _touches;
}

- (NSUInteger) numberOfTouches
{
    return _touches.count;
}

- (void) touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event
{
    if (!_touches) {
        _touches = [NSMutableSet setWithSet:touches];
        [self fireWithState:UIGestureRecognizerStateBegan];
    }
}

- (void) touchesMoved:(NSSet*)touches withEvent:(AP_Event*)event
{
    for (AP_Touch* t in _touches) {
        if (t.phase == UITouchPhaseMoved) {
            [self fireWithState:UIGestureRecognizerStateChanged];
            return;
        }
    }
}

- (void) touchesEnded:(NSSet*)touches withEvent:(AP_Event*)event
{
    if (_touches) {
        [_touches minusSet:touches];
        if ([_touches count] == 0) {
            [self fireWithState:UIGestureRecognizerStateEnded];
            [self reset];
        }
    }
}

- (void) touchesCancelled:(NSSet*)touches withEvent:(AP_Event*)event
{
    if (_touches) {
        [_touches minusSet:touches];
        if ([_touches count] == 0) {
            [self fireWithState:UIGestureRecognizerStateCancelled];
            [self reset];
        }
    }
}

- (void) reset
{
    _touches = nil;
    [super reset];
}

- (CGPoint) velocityInView:(AP_View *)view
{
    AP_NOT_IMPLEMENTED;
    return CGPointZero;
}

- (CGPoint) translationInView:(AP_View*)view
{
    CGPoint translation = CGPointZero;
    for (AP_Touch* t in _touches) {
        translation.x += (t.windowPos.x - t.initialWindowPos.x);
        translation.y += (t.windowPos.y - t.initialWindowPos.y);
    }
    translation.x /= [_touches count];
    translation.y /= [_touches count];
    return translation;
}

@end
