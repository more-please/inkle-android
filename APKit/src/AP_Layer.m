#import "AP_Layer.h"

#import "AP_Check.h"
#import "AP_View.h"

@implementation AP_Layer

AP_BAN_EVIL_INIT

- (instancetype) initWithView:(AP_View*)view
{
    self = [super init];
    if (self) {
        _view = view;

        _zPosition = 0;

        _shadowColor = [UIColor blackColor].CGColor;
        _shadowOpacity = 0;
        _shadowOffset = CGSizeMake(0, -3);
        _shadowRadius = 3;
        _cornerRadius = 0;
    }
    return self;
}

- (CGPoint) anchorPoint
{
    return _view.animatedAnchor.dest;
}

- (void) setAnchorPoint:(CGPoint)p
{
    CGPoint oldCenter = _view.center;
    _view.animatedAnchor.dest = p;
    _view.center = oldCenter;
}

- (CGPoint) position
{
    return _view.center;
}

- (void) setPosition:(CGPoint)p
{
    _view.center = p;
}

- (void) setZPosition:(CGFloat)zPosition
{
    if (zPosition != _zPosition) {
        _zPosition = zPosition;
        [_view zOrderChanged];
    }
}

- (void) removeAllAnimations
{
    for (AP_AnimatedProperty* p in _view.animatedProperties) {
        [p leaveAnimation];
    }
}

@end
