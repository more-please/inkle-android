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

@implementation AP_PinchGestureRecognizer
@end

@implementation AP_PanGestureRecognizer {
    NSMutableSet* _touches;
    CGPoint _translation;
}

- (void) touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event
{
    if (!_touches) {
        _touches = [NSMutableSet setWithSet:touches];
        _translation = CGPointZero;
        [self fireWithState:UIGestureRecognizerStateBegan];
    }
}

- (void) touchesMoved:(NSSet*)touches withEvent:(AP_Event*)event
{
    BOOL gotGesture = NO;
    for (AP_Touch* t in _touches) {
        if (t.phase == UITouchPhaseMoved) {
            gotGesture = YES;
            break;
        }
    }

    if (gotGesture) {
        _translation = CGPointZero;
        for (AP_Touch* t in _touches) {
            _translation.x += (t.windowPos.x - t.initialWindowPos.x);
            _translation.y += (t.windowPos.y - t.initialWindowPos.y);
        }
        _translation.x /= [_touches count];
        _translation.y /= [_touches count];

        [self fireWithState:UIGestureRecognizerStateChanged];
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
    // Not sure what difference the view is supposed to make...
    return _translation;
}

@end
