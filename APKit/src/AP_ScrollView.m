#import "AP_ScrollView.h"

#import "AP_AnimatedProperty.h"
#import "AP_Check.h"
#import "AP_GestureRecognizer.h"
#import "AP_Window.h"

const CGFloat UIScrollViewDecelerationRateNormal = 5.0;
const CGFloat UIScrollViewDecelerationRateFast = 25.0;

@implementation AP_ScrollView {
    AP_AnimatedSize* _animatedContentSize;
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
        self.allowSubviewHitTestOutsideBounds = YES;
        _enabled = YES;
        _animatedContentSize = [[AP_AnimatedSize alloc] initWithName:@"contentSize" view:self];
        _decelerationRate = UIScrollViewDecelerationRateNormal;
        _gesture = [[AP_PanGestureRecognizer alloc] initWithTarget:self action:@selector(pan)];
        [self addGestureRecognizer:_gesture];
    }
    return self;
}

// --------------------
// For CustomScrollView

- (void) setContentSize:(CGSize)contentSize offset:(CGPoint)offset
{
    self.contentSize = contentSize;
    self.contentOffset = offset;
}

- (void) setHorizontal:(BOOL)horizontal
{
    self.directionalLockEnabled = horizontal;
}

- (int) pageIndex
{
    CGPoint pos = self.contentOffset;
    CGSize size = self.bounds.size;
    if (_directionalLockEnabled) {
        return roundf(pos.x / size.width);
    } else {
        return roundf(pos.y / size.height);
    }
}

- (void) setPageIndex:(int)i
{
    CGPoint pos = self.contentOffset;
    CGSize size = self.bounds.size;
    if (_directionalLockEnabled) {
        pos.x = i * size.width;
    } else {
        pos.y = i * size.height;
    }
    self.contentOffset = pos;
}

// --------------------

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;
{
    if (animated) {
        [AP_View animateWithDuration:1.0f animations:^{
            self.contentOffset = contentOffset;
        }];
    } else {
        self.contentOffset = contentOffset;
    }
}

- (void)scrollToBottom
{
    [self.animatedBoundsOrigin leaveAnimation];
    CGPoint bottom = {
        MAX(0, self.contentSize.width - self.bounds.size.width),
        MAX(0, self.contentSize.height - self.bounds.size.height)
    };
    CGPoint delta = {
        bottom.x - self.contentOffset.x,
        bottom.y - self.contentOffset.y
    };
    CGFloat distance = sqrt(delta.x * delta.x + delta.y * delta.y);
    CGFloat speed = [AP_Window scaleForIPhone:20 iPad:40];

    if (distance > 0) {
        [AP_View animateWithDuration:(distance / speed)
            delay:0.5
            options:UIViewAnimationOptionAllowUserInteraction
            animations:^{
                self.contentOffset = bottom;
            }
            completion:nil
        ];
    }
}

- (CGPoint) contentOffset
{
    return self.bounds.origin;
}

- (CGPoint) maxContentOffset
{
    CGSize boundsSize = self.bounds.size;
    CGSize contentSize = self.contentSize;
    CGPoint p = {
        MAX(0, contentSize.width - boundsSize.width),
        MAX(0, contentSize.height - boundsSize.height)
    };
    return p;
}

- (void) setContentOffset:(CGPoint)offset;
{
    AP_AnimatedPoint* origin = self.animatedBoundsOrigin;
    if (!CGPointEqualToPoint(offset, origin.dest)) {
        origin.dest = offset;
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

- (CGSize) contentSize
{
    return _animatedContentSize.dest;
}

- (void) setContentSize:(CGSize)contentSize
{
    if (CGSizeEqualToSize(contentSize, _animatedContentSize.dest)) {
        return;
    }

    CGPoint offset = self.contentOffset;
    _animatedContentSize.dest = contentSize;

    CGPoint maxOffset = self.maxContentOffset;
    self.contentOffset = CGPointMake(
        MAX(0, MIN(maxOffset.x, offset.x)),
        MAX(0, MIN(maxOffset.y, offset.y))
    );

    [self setNeedsLayout];
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    CGSize contentSize = self.contentSize;
    CGSize size = self.bounds.size;
    _gesture.preventHorizontalMovement = (contentSize.width <= size.width);
    _gesture.preventVerticalMovement = (contentSize.height <= size.height);
}

- (void) pan
{
    if (_enabled && _gesture.state == UIGestureRecognizerStateBegan) {
        [self.animatedBoundsOrigin leaveAnimation];
        _inGesture = YES;
        _previousTranslation = [_gesture translationInView:nil];
        _nextTranslation = _previousTranslation;
        if ([_delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
            [_delegate scrollViewWillBeginDragging:self];
        }
    } else if (_enabled && _gesture.state == UIGestureRecognizerStateChanged) {
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

- (void) updateGL:(float)timeStep
{
    [super updateGL:timeStep];

    if (_inGesture) {
        _velocity.x = _previousTranslation.x - _nextTranslation.x;
        _velocity.y = _previousTranslation.y - _nextTranslation.y;
        _previousTranslation = _nextTranslation;
        if (_directionalLockEnabled) {
            if (fabs(_velocity.x) < fabs(_velocity.y)) {
                _velocity.x = 0;
            } else {
                _velocity.y = 0;
            }
        }
    }

    CGPoint pos = self.contentOffset;
    CGSize size = self.bounds.size;
    CGSize contentSize = self.contentSize;

    if (_velocity.x != 0 || _velocity.y != 0) {
        pos.x += _velocity.x;
        pos.y += _velocity.y;

        pos.x = MAX(0, MIN(contentSize.width - size.width, pos.x));
        pos.y = MAX(0, MIN(contentSize.height - size.height, pos.y));

        self.contentOffset = pos;
    }

    static const float kMinSpeed = 5;

    // What velocity would we need to snap to the current page at the minimum speed?
    CGPoint idealVelocity = CGPointZero;
    if (_pagingEnabled) {
        CGPoint idealPage = { roundf(pos.x / size.width), roundf(pos.y / size.height) };
        CGPoint idealPos = { idealPage.x * size.width, idealPage.y * size.height };
        idealVelocity.x = sqrt(size.width) * (idealPos.x - pos.x) / size.width;
        idealVelocity.y = sqrt(size.height) * (idealPos.y - pos.y) / size.height;
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
