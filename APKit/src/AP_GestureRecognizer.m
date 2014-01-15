#import "AP_GestureRecognizer.h"

#import "AP_Check.h"

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

- (void) fire
{
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

@implementation AP_PanGestureRecognizer

- (CGPoint) velocityInView:(AP_View *)view
{
    AP_NOT_IMPLEMENTED;
    return CGPointZero;
}

- (CGPoint) translationInView:(AP_View*)view
{
    AP_NOT_IMPLEMENTED;
    return CGPointZero;
}

@end
