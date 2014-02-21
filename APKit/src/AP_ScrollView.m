#import "AP_ScrollView.h"

#import "AP_Check.h"
#import "AP_GestureRecognizer.h"

#ifdef ANDROID
const CGFloat UIScrollViewDecelerationRateNormal = 5.0;
const CGFloat UIScrollViewDecelerationRateFast = 25.0;
#endif

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
        [AP_View animateWithDuration:1.0 animations:^{
            self.contentOffset = contentOffset;
        }];
    } else {
        self.contentOffset = contentOffset;
    }
}

- (CGPoint) contentOffset
{
    return self.bounds.origin;
}

- (void) setContentOffset:(CGPoint)offset;
{
    CGSize size = self.frame.size;
    offset.x = MAX(0, MIN(_contentSize.width - size.width, offset.x));
    offset.y = MAX(0, MIN(_contentSize.height - size.height, offset.y));

    AP_AnimatedPoint* origin = self.animatedBoundsOrigin;
    if (!CGPointEqualToPoint(offset, origin.dest)) {
        origin.dest = offset;
        [self setNeedsLayout];
        if ([_delegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
            [_delegate scrollViewDidScroll:self];
        }
    }
}

- (void) setBounds:(CGRect)bounds
{
    CGPoint p = self.contentOffset;
    [super setBounds:bounds];
    if (!CGPointEqualToPoint(p, self.contentOffset)) {
        [self setNeedsLayout];
        if ([_delegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
            [_delegate scrollViewDidScroll:self];
        }
    }
}

- (void) setContentSize:(CGSize)contentSize
{
    CGPoint offset = self.contentOffset;
    _contentSize = contentSize;
    self.contentOffset = offset;
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    CGSize size = self.frame.size;
    _gesture.preventHorizontalMovement = (_contentSize.width <= size.width);
    _gesture.preventVerticalMovement = (_contentSize.height <= size.height);
}

- (void) pan
{
    if (_gesture.state == UIGestureRecognizerStateBegan) {
        _inGesture = YES;
        _previousTranslation = [_gesture translationInView:nil];
        _nextTranslation = _previousTranslation;
        if ([_delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
            [_delegate scrollViewWillBeginDragging:self];
        }
    } else if (_gesture.state == UIGestureRecognizerStateChanged) {
        _nextTranslation = [_gesture translationInView:nil];
    } else {
        _inGesture = NO;
        BOOL decelerate = (_velocity.x != 0 || _velocity.y != 0);
        if ([_delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
            [_delegate scrollViewDidEndDragging:self willDecelerate:decelerate];
        }
    }
}

static CGFloat magnitude(CGFloat x, CGFloat y) {
    return sqrt(x * x + y * y);
}

- (void) updateGL
{
    // Measure the time step since the previous call
    static double previousTime = 0;
    double time = CACurrentMediaTime();
    double timeStep = MAX(0.01, MIN(1, time - previousTime));
    previousTime = time;

    if (_inGesture) {
        _velocity.x = _previousTranslation.x - _nextTranslation.x;
        _velocity.y = _previousTranslation.y - _nextTranslation.y;
        _previousTranslation = _nextTranslation;
        if (_directionalLockEnabled) {
            if (abs(_velocity.x) < abs(_velocity.y)) {
                _velocity.x = 0;
            } else {
                _velocity.y = 0;
            }
        }
    }

    // Get the current velocity per second (not per frame!)
    float vCurrent = magnitude(_velocity.x / timeStep, _velocity.y / timeStep);
    if (vCurrent > 0) {
        CGPoint p = self.contentOffset;
        p.x += _velocity.x;
        p.y += _velocity.y;
        self.contentOffset = p;

        // Velocity decay
        static const float kMinSpeed = 5;
        float decay = exp(-_decelerationRate * timeStep);
        float vNext = (vCurrent + kMinSpeed) * decay - kMinSpeed;
        if (vNext < 0) {
            vNext = 0;
        }
        _velocity.x *= vNext / vCurrent;
        _velocity.y *= vNext / vCurrent;

        if (_velocity.x == 0 && _velocity.y == 0) {
            if ([_delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
                [_delegate scrollViewDidEndDecelerating:self];
            }
        }
    }
}

@end
