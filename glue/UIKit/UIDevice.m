#import "UIDevice.h"

#import <CoreGraphics/CoreGraphics.h>

#import "GlueCommon.h"
#import "UIScreen.h"

@implementation UIDevice

+ (UIDevice*) currentDevice
{
    static UIDevice* g_CurrentDevice;
    if (!g_CurrentDevice) {
        g_CurrentDevice = [[UIDevice alloc] init];
    }
    return g_CurrentDevice;
}

- (UIDeviceOrientation) orientation
{
    CGRect r = [UIScreen mainScreen].bounds;
    return (r.size.width > r.size.height) ? UIDeviceOrientationLandscapeLeft : UIDeviceOrientationPortrait;
}

- (UIUserInterfaceIdiom) userInterfaceIdiom
{
    CGRect r = [UIScreen mainScreen].bounds;
    float width = MIN(r.size.width, r.size.height);
    // Arbitrary phone/tablet cutoff. The Nexus 7 (a small tablet) is 961x600.
    return (width >= 512) ? UIUserInterfaceIdiomPad : UIUserInterfaceIdiomPhone;
}

- (void)beginGeneratingDeviceOrientationNotifications
{
    GLUE_NOT_IMPLEMENTED;
}

- (void)endGeneratingDeviceOrientationNotifications;
{
    GLUE_NOT_IMPLEMENTED;
}

@end
