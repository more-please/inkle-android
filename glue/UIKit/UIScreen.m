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
        _scale = 1.0;
    }
    return self;
}

- (void) setSize:(CGSize)size scale:(CGFloat)scale
{
    _bounds = CGRectMake(0, 0, size.width, size.height);
    _scale = scale;
}

@end
