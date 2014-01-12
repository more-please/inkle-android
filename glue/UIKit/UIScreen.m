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
    return _bounds.size.height - _applicationFrame.size.height;
}

- (void) setBounds:(CGRect)bounds applicationFrame:(CGRect)frame scale:(CGFloat)scale
{
    _bounds = bounds;
    _applicationFrame = frame;
    _scale = scale;
}

@end
