#import "AP_ScrollView.h"

#import "AP_Check.h"
#import "AP_GestureRecognizer.h"

@implementation AP_ScrollView {
    AP_PanGestureRecognizer* _gesture;
    BOOL _inGesture;
    CGPoint _previousTranslation;
    CGPoint _nextTranslation;
    CGPoint _velocity;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _decelerationRate = UIScrollViewDecelerationRateNormal;
        _gesture = [[AP_PanGestureRecognizer alloc] initWithTarget:self action:@selector(pan)];
        [self addGestureRecognizer:_gesture];
    }
    return self;
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;
{
    if (animated) {
        AP_NOT_IMPLEMENTED;
    }
    self.contentOffset = contentOffset;
}

- (CGPoint) contentOffset
{
    return self.bounds.origin;
}

- (void) setContentOffset:(CGPoint)offset;
{
    CGRect r = self.bounds;
    r.origin = offset;
    self.bounds = r;
}

- (void) pan
{
    if (_gesture.state == UIGestureRecognizerStateBegan) {
        _inGesture = YES;
        _previousTranslation = [_gesture translationInView:nil];
        _nextTranslation = _previousTranslation;
    } else if (_gesture.state == UIGestureRecognizerStateChanged) {
        _nextTranslation = [_gesture translationInView:nil];
    } else {
        _inGesture = NO;
    }
}

- (void) updateGL
{
    // Measure the time step since the previous call
    static double previousTime = 0;
    double time = CACurrentMediaTime();
    double timeStep = (time - previousTime);
    if (timeStep > 1) {
        timeStep = 1;
    }
    previousTime = time;

    if (_inGesture) {
        _velocity.x = _previousTranslation.x - _nextTranslation.x;
        _velocity.y = _previousTranslation.y - _nextTranslation.y;
        _previousTranslation = _nextTranslation;
    }

    float vCurrent = sqrtf(_velocity.x * _velocity.x + _velocity.y * _velocity.y);
    if (vCurrent > 0) {
        CGPoint p = self.contentOffset;
        p.x += _velocity.x;
        p.y += _velocity.y;

        CGSize size = self.frame.size;
        p.x = MAX(0, MIN(_contentSize.width - size.width, p.x));
        p.y = MAX(0, MIN(_contentSize.height - size.height, p.y));
        self.contentOffset = p;

        // Velocity decay
        static const float kDecayPerSecond = 4.0f;
        static const float kFriction = 0.001f;
        float decay = exp(-kDecayPerSecond * timeStep);
        float vNext = (vCurrent + kFriction) * decay - kFriction;
        if (vNext < 0) {
            vNext = 0;
        }
        _velocity.x *= vNext / vCurrent;
        _velocity.y *= vNext / vCurrent;
    }
}

@end
