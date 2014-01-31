#import "AP_GestureRecognizer.h"

#import "AP_Check.h"
#import "AP_Touch.h"

const float kMaxTapDistance = 3;

static inline CGFloat distance(CGPoint a, CGPoint b) {
    CGPoint p = {a.x - b.x, a.y - b.y};
    return sqrtf(p.x * p.x + p.y * p.y);
}

@implementation AP_GestureRecognizer {
    __weak id _target;
    SEL _action;
    IMP _imp;
    int _numArgs;
    NSMutableDictionary* _touchValues;
}

- (void) setEnabled:(BOOL)enabled
{
    if (_enabled != enabled) {
        _enabled = enabled;
        [self reset];
    }
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
    [self reset];
}

- (void) fireWithState:(UIGestureRecognizerState)state
{
    _state = state;
    AP_CHECK(_state != UIGestureRecognizerStatePossible, return);
    if (_enabled) {
        if (_numArgs == 2) {
            void (*func)(id, SEL) = (void*) _imp;
            func(_target, _action);
        } else {
            AP_CHECK(_numArgs == 3, return);
            void (*func)(id, SEL, id) = (void*) _imp;
            func(_target, _action, self);
        }
    }
}

- (BOOL) shouldRecognizeSimultaneouslyWithGestureRecognizer:(AP_GestureRecognizer*)other
{
    if (other == self) {
        return YES;
    }
    if ([_delegate respondsToSelector:@selector(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)]) {
        return [_delegate gestureRecognizer:self shouldRecognizeSimultaneouslyWithGestureRecognizer:other];
    } else {
        return NO;
    }
}

- (void) touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event {}
- (void) touchesMoved:(NSSet*)touches withEvent:(AP_Event*)event {}

- (void) touchesEnded:(NSSet*)touches withEvent:(AP_Event*)event
{
    if (_touches.count >= 1) {
        [_touches minusSet:touches];
        if ([_touches count] == 0) {
            [self fireWithState:UIGestureRecognizerStateEnded];
            [self reset];
        }
    }
}

- (void) touchesCancelled:(NSSet*)touches withEvent:(AP_Event*)event
{
    if (_touches.count >= 1) {
        [_touches minusSet:touches];
        if ([_touches count] == 0) {
            [self fireWithState:UIGestureRecognizerStateCancelled];
            [self reset];
        }
    }
}

- (CGPoint) locationInView:(AP_View*)view
{
    CGPoint pos = CGPointZero;
    for (AP_Touch* t in _touches) {
        pos.x += t.windowPos.x / _touches.count;
        pos.y += t.windowPos.y / _touches.count;
    }
    return [view convertPoint:pos fromView:nil];
}

- (NSUInteger) numberOfTouches
{
    return _touches.count;
}

- (void) addTouch:(AP_Touch*)touch
{
    [_touches addObject:touch];
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
    [_touches removeAllObjects];
    [_touchValues removeAllObjects];
    if (_state == UIGestureRecognizerStateBegan || _state == UIGestureRecognizerStateChanged) {
        [self fireWithState:UIGestureRecognizerStateCancelled];
    }
    _state = UIGestureRecognizerStatePossible;
}

@end

@implementation AP_TapGestureRecognizer {
    CGPoint _origin;
}

- (void) touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event
{
    // Only count the initial touch(es)
    if (self.touches.count == 0) {
        for (AP_Touch* t in touches) {
            [self addTouch:t];
        }
        _origin = [self locationInView:self.view];
    }
}

- (void) touchesMoved:(NSSet*)touches withEvent:(AP_Event*)event
{
    CGPoint p = [self locationInView:self.view];
    if (distance(p, _origin) > kMaxTapDistance) {
        [self reset];
    }
}

- (void) touchesEnded:(NSSet*)touches withEvent:(AP_Event*)event
{
    CGPoint p = [self locationInView:self.view];
    if (distance(p, _origin) > kMaxTapDistance) {
        [self reset];
        return;
    }
    for (AP_Touch* t in self.touches) {
        if (t.phase != UITouchPhaseEnded) {
            [super touchesEnded:touches withEvent:event];
            return;
        }
    }
    [self fireWithState:UIGestureRecognizerStateEnded];
    [self reset];
}

@end

@implementation AP_LongPressGestureRecognizer
@end

@interface AP_Pinch_Value : NSObject
@property(nonatomic) CGPoint initialPos;
@end

@implementation AP_Pinch_Value
@end

@implementation AP_PinchGestureRecognizer {
    CGPoint _origin;
    float _initialScale;
}

- (void) touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event
{
    if (self.touches.count >= 2) {
        // Adding more touches to an existing gesture,
        // make sure we don't change the scale.
        _initialScale = self.scale;
    }

    for (AP_Touch* t in touches) {
        [self addTouch:t withValue:[[AP_Pinch_Value alloc] init]];
    }
    for (AP_Touch* t in self.touches) {
        AP_Pinch_Value* value = [self valueForTouch:t];
        value.initialPos = t.windowPos;
    }

    if (self.touches.count == 1) {
        // Could be a gesture but not yet.
        _initialScale = 1;
    } else if (self.state == UIGestureRecognizerStatePossible) {
        // Started zooming. Fix the origin now.
        _origin = CGPointZero;
        for (AP_Touch* t in self.touches) {
            AP_Pinch_Value* v = [self valueForTouch:t];
            _origin.x += v.initialPos.x / self.touches.count;
            _origin.y += v.initialPos.y / self.touches.count;
        }
        [self fireWithState:UIGestureRecognizerStateBegan];
    } else {
        // Resuming a suspended gesture.
        // 'initial state' was saved on the last touchesEnded.
        [self fireWithState:UIGestureRecognizerStateChanged];
    }
}

- (void) touchesMoved:(NSSet*)touches withEvent:(AP_Event*)event
{
    if (self.touches.count >= 2) {
        for (AP_Touch* t in self.touches) {
            if (t.phase == UITouchPhaseMoved) {
                [self fireWithState:UIGestureRecognizerStateChanged];
                return;
            }
        }
    }
}

- (void) touchesEnded:(NSSet*)touches withEvent:(AP_Event*)event
{
    float oldScale = self.scale;
    [super touchesEnded:touches withEvent:event];
    if (self.touches.count == 1) {
        // Gesture paused -- stash the current scale.
        _initialScale = oldScale;
    }
}

- (void) touchesCancelled:(NSSet*)touches withEvent:(AP_Event*)event
{
    float oldScale = self.scale;
    [super touchesCancelled:touches withEvent:event];
    if (self.touches.count == 1) {
        // Gesture paused -- stash the current scale.
        _initialScale = oldScale;
    }
}

- (CGFloat)scale
{
    NSSet* touches = self.touches;
    if (touches.count == 0) {
        return 1.0;
    }
    if (touches.count == 1) {
        // Gesture is paused, return the last known scale.
        return _initialScale;
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

    float kFudge = 30; // Make very small pinches more stable
    float averageScale = (newDist + kFudge) / (oldDist + kFudge);
    return averageScale * _initialScale;
}

- (CGPoint) locationInView:(AP_View*)view
{
    return _origin;
}

@end

@interface AP_Pan_Value : NSObject
@property(nonatomic) CGPoint initialPos;
@end

@implementation AP_Pan_Value
@end

@implementation AP_PanGestureRecognizer

- (void) zapTranslation:(CGPoint)translation
{
    for (AP_Touch* t in self.touches) {
        // Give this touch an initial value such that its impact
        // on the given translation is zero.
        CGPoint p = t.windowPos;
        p.x -= translation.x;
        p.y -= translation.y;
        AP_Pan_Value* value = [self valueForTouch:t];
        value.initialPos = p;
    }
}

- (void) maybeStartedOrChanged
{
    if (self.state == UIGestureRecognizerStatePossible) {
        if (distance(CGPointZero, [self translationInView:nil]) > kMaxTapDistance) {
            [self fireWithState:UIGestureRecognizerStateBegan];
        }
    } else {
        [self fireWithState:UIGestureRecognizerStateChanged];
    }
}

- (void) touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event
{
    CGPoint currentTranslation = [self translationInView:nil];
    for (AP_Touch* t in touches) {
        [self addTouch:t withValue:[[AP_Pan_Value alloc] init]];
    }
    [self zapTranslation:currentTranslation];
    [self maybeStartedOrChanged];
}

- (void) touchesMoved:(NSSet*)touches withEvent:(AP_Event*)event
{
    for (AP_Touch* t in self.touches) {
        if (t.phase == UITouchPhaseMoved) {
            [self maybeStartedOrChanged];
            return;
        }
    }
}

- (void) touchesEnded:(NSSet*)touches withEvent:(AP_Event*)event
{
    CGPoint currentTranslation = [self translationInView:nil];
    [super touchesEnded:touches withEvent:event];
    [self zapTranslation:currentTranslation];
}

- (void) touchesCancelled:(NSSet*)touches withEvent:(AP_Event*)event
{
    CGPoint currentTranslation = [self translationInView:nil];
    [super touchesEnded:touches withEvent:event];
    [self zapTranslation:currentTranslation];
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

@end
