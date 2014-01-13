#import "UIDevice.h"

#import "GlueCommon.h"

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
    GLUE_NOT_IMPLEMENTED;
    return UIDeviceOrientationPortrait;
}

- (UIUserInterfaceIdiom) userInterfaceIdiom
{
//    GLUE_NOT_IMPLEMENTED;
    return UIUserInterfaceIdiomPad;
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
