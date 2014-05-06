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

    CGPoint pos = self.contentOffset;
    CGSize size = self.frame.size;

    if (_velocity.x != 0 || _velocity.y != 0) {
        pos.x += _velocity.x;
        pos.y += _velocity.y;

        pos.x = MAX(0, MIN(_contentSize.width - size.width, pos.x));
        pos.y = MAX(0, MIN(_contentSize.height - size.height, pos.y));

        self.contentOffset = pos;
    }

    static const float kMinSpeed = 5;

    // What velocity would we need to snap to the current page at the minimum speed?
    CGPoint idealVelocity = CGPointZero;
    if (_pagingEnabled) {
        CGPoint idealPage = { roundf(pos.x / size.width), roundf(pos.y / size.height) };
        CGPoint idealPos = { idealPage.x * size.width, idealPage.y * size.height };
        idealVelocity.x = (idealPos.x - pos.x) / size.width * kMinSpeed;
        idealVelocity.y = (idealPos.y - pos.y) / size.height * kMinSpeed;
    }

    // Get our absolute speed, relative to the ideal velocity.
    float speed = magnitude(_velocity.x - idealVelocity.x, _velocity.y - idealVelocity.y);
    if (speed > 0) {
        // Velocity decay
        float decay = exp(-_decelerationRate * timeStep);
        float newSpeed = (speed + kMinSpeed) * decay - kMinSpeed;
        if (newSpeed < 1e-6) {
            newSpeed = 0;
        }
        _velocity.x = idealVelocity.x + (_velocity.x - idealVelocity.x) * newSpeed / speed;
        _velocity.y = idealVelocity.y + (_velocity.y - idealVelocity.y) * newSpeed / speed;

        if (_velocity.x == 0 && _velocity.y == 0 && !_inGesture) {
            if ([_delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
                [_delegate scrollViewDidEndDecelerating:self];
            }
        }
    }
}

@end
