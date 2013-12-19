#import "UIScreen.h"

@implementation UIScreen

static UIScreen* g_Screen;

+ (UIScreen*) mainScreen
{
    if (!g_Screen) {
        g_Screen = [[UIScreen alloc] init];
    }
    return g_Screen;
}

- (id) init
{
    self = [super init];
    if (self) {
//        // For extra fun, Apportable lies about the initial device orientation.
//        AndroidDisplay* display = [AndroidActivity currentActivity].applicationContext.windowManager.defaultDisplay;
//        AndroidDisplayOrientation orientation = display.orientation;
//        BOOL isLandscape = (orientation == AndroidDisplayOrientationLandscapeRight || orientation == AndroidDisplayOrientationLandscapeLeft);
//        g_ScreenScale = display.metrics.density;
//        if (g_ScreenScale < 0.1 || g_ScreenScale > 10 || isnan(g_ScreenScale)) {
//            NSLog(@"Crazy screen density value (%.1f), trying densitydpi", g_ScreenScale);
//            g_ScreenScale = display.metrics.densityDpi / 160.0;
//        }
//        if (g_ScreenScale < 0.1 || g_ScreenScale > 10 || isnan(g_ScreenScale)) {
//            NSLog(@"Screen density still crazy (%.1f), let's just say it's 1.0", g_ScreenScale);
//            g_ScreenScale = 1;
//        }
//        g_ScreenSize = screen.bounds.size;
//        g_ScreenSize = CGSizeMake(g_ScreenSize.width / g_ScreenScale, g_ScreenSize.height / g_ScreenScale);
        _bounds = CGRectMake(0, 0, 768, 1024);
    }
    return self;
}

@end
