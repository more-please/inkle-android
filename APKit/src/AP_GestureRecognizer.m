#import "AP_GestureRecognizer.h"

#import "AP_Check.h"
#import "AP_Touch.h"

@implementation AP_GestureRecognizer {
    __weak id _target;
    SEL _action;
    IMP _imp;
    int _numArgs;
    NSMutableDictionary* _touchValues;
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

        _touches = [NSMutableSet set];
        _touchValues = [NSMutableDictionary dictionary];
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

- (CGPoint) locationInView:(AP_View*)view
{
    AP_NOT_IMPLEMENTED;
    return CGPointZero;
}

- (NSUInteger) numberOfTouches
{
    return _touches.count;
}

- (void) addTouch:(AP_Touch*)touch withValue:(id)value
{
    [_touches addObject:touch];
    id key = [NSValue valueWithPointer:(__bridge const void*)(touch)];
    [_touchValues setObject:value forKey:key];
}

- (id) valueForTouch:(AP_Touch*)touch
{
    id key = [NSValue valueWithPointer:(__bridge const void*)(touch)];
    return [_touchValues objectForKey:key];
}

- (void) reset
{
    _state = UIGestureRecognizerStatePossible;
    [_touches removeAllObjects];
    [_touchValues removeAllObjects];
}

@end

@implementation AP_TapGestureRecognizer
@end

@implementation AP_LongPressGestureRecognizer
@end

@interface AP_Pinch_Value : NSObject
@property(nonatomic) CGPoint initialPos;
@end

@implementation AP_Pinch_Value
@end

@implementation AP_PinchGestureRecognizer

- (void) touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event
{
    if (self.state == UIGestureRecognizerStatePossible && event.allTouches.count >= 2) {
        for (AP_Touch* t in event.allTouches) {
            AP_Pinch_Value* value = [[AP_Pinch_Value alloc] init];
            value.initialPos = t.windowPos;
            [self addTouch:t withValue:value];
        }
        [self fireWithState:UIGestureRecognizerStateBegan];
    }
}

- (void) touchesMoved:(NSSet*)touches withEvent:(AP_Event*)event
{
    for (AP_Touch* t in self.touches) {
        if (t.phase == UITouchPhaseMoved) {
            [self fireWithState:UIGestureRecognizerStateChanged];
            return;
        }
    }
}

- (void) touchesEnded:(NSSet*)touches withEvent:(AP_Event*)event
{
    if (self.touches.count >= 2) {
        [self.touches minusSet:touches];
        if ([self.touches count] < 2) {
            [self fireWithState:UIGestureRecognizerStateEnded];
            [self reset];
        }
    }
}

- (void) touchesCancelled:(NSSet*)touches withEvent:(AP_Event*)event
{
    if (self.touches.count >= 2) {
        [self.touches minusSet:touches];
        if ([self.touches count] < 2) {
            [self fireWithState:UIGestureRecognizerStateCancelled];
            [self reset];
        }
    }
}

static inline CGFloat distance(CGPoint a, CGPoint b) {
    CGPoint p = {a.x - b.x, a.y - b.y};
    return sqrtf(p.x * p.x + p.y * p.y);
}

- (CGFloat)scale
{
    NSSet* touches = self.touches;
    if (touches.count < 2) {
        return 1.0;
    }

    CGPoint oldCenter = CGPointZero;
    CGPoint newCenter = CGPointZero;
    for (AP_Touch* t in touches) {
        AP_Pinch_Value* v = [self valueForTouch:t];
        oldCenter.x += v.initialPos.x / touches.count;
        oldCenter.y += v.initialPos.y / touches.count;
        newCenter.x += t.windowPos.x / touches.count;
        newCenter.y += t.windowPos.y / touches.count;
    }

    CGFloat oldDist = 0;
    CGFloat newDist = 0;
    for (AP_Touch* t in touches) {
        AP_Pinch_Value* v = [self valueForTouch:t];
        oldDist += distance(v.initialPos, oldCenter) / touches.count;
        newDist += distance(t.windowPos, newCenter) / touches.count;
    }

    return (oldDist == 0) ? 1 : (newDist / oldDist);
}

- (CGPoint) locationInView:(AP_View*)view
{
    NSSet* touches = self.touches;
    if (touches.count < 2) {
        return CGPointZero;
    }

    CGPoint oldCenter = CGPointZero;
    for (AP_Touch* t in touches) {
        AP_Pinch_Value* v = [self valueForTouch:t];
        oldCenter.x += v.initialPos.x / touches.count;
        oldCenter.y += v.initialPos.y / touches.count;
    }
    return oldCenter;
}

@end

@interface AP_Pan_Value : NSObject
@property(nonatomic) CGPoint initialPos;
@end

@implementation AP_Pan_Value
@end

@implementation AP_PanGestureRecognizer

- (void) touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event
{
    CGPoint currentTranslation = [self translationInView:nil];

    for (AP_Touch* t in touches) {
        // Give this touch an initial value such that its impact
        // on the current translation is zero.
        CGPoint p = t.windowPos;
        p.x -= currentTranslation.x;
        p.y -= currentTranslation.y;

        AP_Pan_Value* value = [[AP_Pan_Value alloc] init];
        value.initialPos = p;
        [self addTouch:t withValue:value];
    }

    if (self.state == UIGestureRecognizerStatePossible) {
        [self fireWithState:UIGestureRecognizerStateBegan];
    } else {
        [self fireWithState:UIGestureRecognizerStateChanged];
    }
}

- (void) touchesMoved:(NSSet*)touches withEvent:(AP_Event*)event
{
    for (AP_Touch* t in self.touches) {
        if (t.phase == UITouchPhaseMoved) {
            [self fireWithState:UIGestureRecognizerStateChanged];
            return;
        }
    }
}

- (void) touchesEnded:(NSSet*)touches withEvent:(AP_Event*)event
{
    if (self.touches.count >= 1) {
        [self.touches minusSet:touches];
        if ([self.touches count] < 1) {
            [self fireWithState:UIGestureRecognizerStateEnded];
            [self reset];
        }
    }
}

- (void) touchesCancelled:(NSSet*)touches withEvent:(AP_Event*)event
{
    if (self.touches.count >= 1) {
        [self.touches minusSet:touches];
        if ([self.touches count] < 1) {
            [self fireWithState:UIGestureRecognizerStateCancelled];
            [self reset];
        }
    }
}

- (CGPoint) translationInView:(AP_View*)view
{
    NSSet* touches = self.touches;
    CGPoint delta = CGPointZero;
    for (AP_Touch* t in touches) {
        AP_Pinch_Value* v = [self valueForTouch:t];
        delta.x += (t.windowPos.x - v.initialPos.x) / touches.count;
        delta.y += (t.windowPos.y - v.initialPos.y) / touches.count;
    }
    return delta;
}

- (CGPoint) locationInView:(AP_View*)view
{
    NSSet* touches = self.touches;
    CGPoint pos = CGPointZero;
    for (AP_Touch* t in touches) {
        pos.x += t.windowPos.x / touches.count;
        pos.y += t.windowPos.y / touches.count;
    }
    return pos;
}

@end
