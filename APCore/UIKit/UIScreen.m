#import "UIScreen.h"

@implementation UIScreen

+ (UIScreen*) mainScreen
{
    static UIScreen* g_Screen;
    if (!g_Screen) {
        g_Screen = [[UIScreen alloc] init];
    }
    return g_Screen;
}

- (id) init
{
    self = [super init];
    if (self) {
        _bounds = CGRectMake(0, 0, 768, 1024);
        _applicationFrame = _bounds;
        _scale = 1.0;
    }
    return self;
}

- (CGFloat) statusBarHeight
{
    CGFloat result = _applicationFrame.origin.y - _bounds.origin.y;
//     NSLog(@"*** statusBarHeight: %f", result);
    return result;
}

- (void) setBounds:(CGRect)bounds applicationFrame:(CGRect)frame scale:(CGFloat)scale
{
    if (bounds.size.width <= 0 || bounds.size.height <= 0 || scale <= 0) {
        NSLog(@"*** Ignoring invalid screen size: %f %f scale: %f", bounds.size.width, bounds.size.height, scale);
        return;
    }
    // The navigation bar sometimes is and sometimes isn't counted in the bounds, bah.
    // To fix that, assume that the screen ends at the bottom-right of the frame.
    _bounds = CGRectMake(
        bounds.origin.x,
        bounds.origin.y,
        CGRectGetMaxX(frame) - bounds.origin.x,
        CGRectGetMaxY(frame) - bounds.origin.y
    );
    _applicationFrame = frame;
    _scale = scale;
}

@end
