#import "AP_GestureRecognizer.h"

#import <vector>

#import "AP_Animation.h"
#import "AP_Check.h"
#import "AP_Touch.h"

static inline CGFloat length(CGPoint p) {
    return sqrtf(p.x * p.x + p.y * p.y);
}

static inline CGFloat distance(CGPoint a, CGPoint b) {
    CGPoint p = {a.x - b.x, a.y - b.y};
    return length(p);
}

// Remembers old positions, for the purposes of velocity calculation.
template <typename T> class FiftyMillisecondBuffer {
public:
    void clear() {
        _values.clear();
        _times.clear();
    }
    void add(T value, NSTimeInterval t) {
        _values.push_back(value);
        _times.push_back(t);
    }
    void get(T& pOut, NSTimeInterval& tOut) const {
        return getAtTime([AP_Animation masterClock], pOut, tOut);
    }
    void getAtTime(NSTimeInterval t, T& pOut, NSTimeInterval& tOut) const {
        // Try to return a value at least 50ms old.
        // If we don't find one, pretend it's that old anyway -- this helps
        // stop things scrolling like crazy after a brief touch.
        tOut = t - 0.05;
        for (int i = _times.size(); i > 0; --i) {
            pOut = _values[i - 1];
            if (_times[i - 1] < tOut) {
                tOut = _times[i - 1];
                return;
            }
        }
    }
private:
    std::vector<T> _values;
    std::vector<NSTimeInterval> _times;
};

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
        _maxTapDistance = 10;

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
    _view = view;
    [self reset];
}

- (void) fireWithState:(UIGestureRecognizerState)state
{
//    NSLog(@"Gesture recognizer: %@ view: %@ firing with state:%d", self, _view, state);
    _state = state;
    AP_CHECK(_state != UIGestureRecognizerStatePossible, return);
    if (_enabled) {
        if (_cancelsTouchesInView) {
            [_view touchesCancelled:_touches withEvent:nil];
        }
        if (_numArgs == 2) {
            void (*func)(id, SEL) = (void(*)(id, SEL)) _imp;
            func(_target, _action);
        } else {
            AP_CHECK(_numArgs == 3, return);
            void (*func)(id, SEL, id) = (void(*)(id, SEL, id)) _imp;
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

- (void) touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event
{
    [self checkForStaleTouches:event];
}

- (void) touchesMoved:(NSSet*)touches withEvent:(AP_Event*)event
{
    [self checkForStaleTouches:event];
}

- (void) touchesEnded:(NSSet*)touches withEvent:(AP_Event*)event
{
    [self checkForStaleTouches:event];

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
    [self checkForStaleTouches:event];

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

- (void) checkForStaleTouches:(AP_Event*)event
{
    NSSet* allTouches = event.allTouches;
    for (AP_Touch* t in _touches) {
        if (![allTouches containsObject:t]) {
//            NSLog(@"Stale touch in gesture recognizer %@, resetting", self);
            [self reset];
            return;
        }
    }
}

@end

@implementation AP_TapDownGestureRecognizer {
    NSTimeInterval _tapTime;
    CGPoint _tapPoint;
    int _tapCount;
}

static NSTimeInterval kDoubleTapTime = 0.5;

- (id) initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if (self) {
        _numberOfTapsRequired = 1;
    }
    return self;
}

- (void) touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event
{
    [self checkForStaleTouches:event];

    // Only count the initial touch(es)
    if (self.touches.count == 0) {
        for (AP_Touch* t in touches) {
            [self addTouch:t];
        }
        NSTimeInterval t = event.timestamp;
        CGPoint p = [self locationInView:self.view];
        if ((t - _tapTime > kDoubleTapTime) || distance(p, _tapPoint) > self.maxTapDistance) {
            _tapCount = 0;
        }
        ++_tapCount;
        _tapPoint = p;
        _tapTime = t;
        if (_tapCount == _numberOfTapsRequired) {
            [self fireWithState:UIGestureRecognizerStateEnded];
        }
    }
}

- (void) touchesEnded:(NSSet*)touches withEvent:(AP_Event*)event
{
    [self reset];
}

- (void) touchesCancelled:(NSSet*)touches withEvent:(AP_Event*)event
{
    [self reset];
}

@end

@implementation AP_TapGestureRecognizer {
    CGPoint _origin;
}

- (void) touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event
{
    [self checkForStaleTouches:event];

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
    [self checkForStaleTouches:event];

    CGPoint p = [self locationInView:self.view];
    if (distance(p, _origin) > self.maxTapDistance) {
        [self reset];
    }
}

- (void) touchesEnded:(NSSet*)touches withEvent:(AP_Event*)event
{
    [self checkForStaleTouches:event];

    CGPoint p = [self locationInView:self.view];
    if (distance(p, _origin) > self.maxTapDistance) {
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

@implementation AP_LongPressGestureRecognizer {
    CGPoint _origin;
    NSTimer* _timer;
}

- (void) reset
{
    [super reset];
    [_timer invalidate];
    _timer = nil;
}

- (void) touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event
{
    [self checkForStaleTouches:event];

    // Only count the initial touch(es)
    if (self.touches.count == 0) {
        for (AP_Touch* t in touches) {
            [self addTouch:t];
        }
        _origin = [self locationInView:self.view];
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timerFired:) userInfo:nil repeats:NO];
    }
}

- (void) timerFired:(NSTimer*)timer
{
    if (timer == _timer) {
        CGPoint p = [self locationInView:self.view];
        if (distance(p, _origin) <= self.maxTapDistance) {
            [self fireWithState:UIGestureRecognizerStateBegan];
        } else {
            [self reset];
        }
    }
}

- (void) touchesMoved:(NSSet*)touches withEvent:(AP_Event*)event
{
    [self checkForStaleTouches:event];

    CGPoint p = [self locationInView:self.view];
    if (distance(p, _origin) > self.maxTapDistance) {
        [self reset];
    }
}

- (void) touchesEnded:(NSSet*)touches withEvent:(AP_Event*)event
{
    [self checkForStaleTouches:event];

    CGPoint p = [self locationInView:self.view];
    if (distance(p, _origin) > self.maxTapDistance) {
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

@interface AP_Pinch_Value : NSObject
@property(nonatomic) CGPoint initialPos;
@end

@implementation AP_Pinch_Value
@end

@implementation AP_PinchGestureRecognizer {
    CGPoint _origin;
    float _initialScale;
    FiftyMillisecondBuffer<CGFloat> _buffer;
}

- (void) reset
{
    _buffer.clear();
    [super reset];
}

- (void) touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event
{
    [self checkForStaleTouches:event];

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

        _buffer.clear();
        _buffer.add(self.scale, event.timestamp);

        [self fireWithState:UIGestureRecognizerStateBegan];
    } else {
        // Resuming a suspended gesture.
        // 'initial state' was saved on the last touchesEnded.
        [self fireWithState:UIGestureRecognizerStateChanged];
    }
}

- (void) touchesMoved:(NSSet*)touches withEvent:(AP_Event*)event
{
    [self checkForStaleTouches:event];

    if (self.touches.count >= 2) {
        for (AP_Touch* t in self.touches) {
            if (t.phase == UITouchPhaseMoved) {
                _buffer.add(self.scale, event.timestamp);
                [self fireWithState:UIGestureRecognizerStateChanged];
                return;
            }
        }
    }
}

- (void) touchesEnded:(NSSet*)touches withEvent:(AP_Event*)event
{
    [self checkForStaleTouches:event];

    float oldScale = self.scale;
    [super touchesEnded:touches withEvent:event];
    if (self.touches.count == 1) {
        // Gesture paused -- stash the current scale.
        _initialScale = oldScale;
    }
}

- (void) touchesCancelled:(NSSet*)touches withEvent:(AP_Event*)event
{
    [self checkForStaleTouches:event];

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

- (CGFloat) velocity
{
    NSTimeInterval t = [AP_Animation masterClock];
    CGFloat lastScale = 0;
    NSTimeInterval lastScaleTime;
    _buffer.getAtTime(t, lastScale, lastScaleTime);

    float dt = t - lastScaleTime;
    if (dt > 0) {
        return (self.scale - lastScale) / dt;
    } else {
        return 0;
    }
}

@end

@interface AP_Pan_Value : NSObject
@property(nonatomic) CGPoint initialPos;
@end

@implementation AP_Pan_Value
@end

@implementation AP_PanGestureRecognizer {
    FiftyMillisecondBuffer<CGPoint> _buffer;
}

- (void) reset
{
    _buffer.clear();
    [super reset];
}

- (CGPoint) velocityInView:(AP_View*)view
{
    CGPoint translation = [self translationInView:nil];
    NSTimeInterval t = [AP_Animation masterClock];

    CGPoint lastTranslation = CGPointZero;
    NSTimeInterval lastTranslationTime;
    _buffer.getAtTime(t, lastTranslation, lastTranslationTime);

    float dt = t - lastTranslationTime;
    if (dt > 0) {
        return CGPointMake(
            (translation.x - lastTranslation.x) / dt,
            (translation.y - lastTranslation.y) / dt
        );
    } else {
        return CGPointZero;
    }
}

- (void) zapTranslation:(CGPoint)translation time:(NSTimeInterval)t
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
    _buffer.clear();
    _buffer.add(translation, t);
}

- (void) maybeStartedOrChanged:(NSTimeInterval)t
{
    CGPoint translation = [self translationInView:nil];
    _buffer.add(translation, t);

    if (self.state == UIGestureRecognizerStatePossible) {
        if (length(translation) > self.maxTapDistance) {
            [self fireWithState:UIGestureRecognizerStateBegan];
        }
    } else {
        [self fireWithState:UIGestureRecognizerStateChanged];
    }
}

- (void) touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event
{
    [self checkForStaleTouches:event];

    CGPoint currentTranslation = [self translationInView:nil];
    for (AP_Touch* t in touches) {
        [self addTouch:t withValue:[[AP_Pan_Value alloc] init]];
    }
    [self zapTranslation:currentTranslation time:event.timestamp];
    [self maybeStartedOrChanged:event.timestamp];
}

- (void) touchesMoved:(NSSet*)touches withEvent:(AP_Event*)event
{
    [self checkForStaleTouches:event];

    for (AP_Touch* t in self.touches) {
        if (t.phase == UITouchPhaseMoved) {
            [self maybeStartedOrChanged:event.timestamp];
            return;
        }
    }
}

- (void) touchesEnded:(NSSet*)touches withEvent:(AP_Event*)event
{
    [self checkForStaleTouches:event];

    CGPoint currentTranslation = [self translationInView:nil];
    [super touchesEnded:touches withEvent:event];
    [self zapTranslation:currentTranslation time:event.timestamp];
}

- (void) touchesCancelled:(NSSet*)touches withEvent:(AP_Event*)event
{
    [self checkForStaleTouches:event];

    CGPoint currentTranslation = [self translationInView:nil];
    [super touchesEnded:touches withEvent:event];
    [self zapTranslation:currentTranslation time:event.timestamp];
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
    if (_preventHorizontalMovement) {
        delta.x = 0;
    }
    if (_preventVerticalMovement) {
        delta.y = 0;
    }
    return delta;
}

@end
