#import "AP_Application.h"

#import "AP_Check.h"

@implementation AP_Application

static AP_Application* g_Application;

+ (AP_Application*) sharedApplication
{
    if (!g_Application) {
        g_Application = [[AP_Application alloc] init];
    }
    return g_Application;
}

- (BOOL) openURL:(NSURL*)url
{
    AP_NOT_IMPLEMENTED;
    return NO;
}

- (BOOL) canOpenURL:(NSURL*)url
{
    AP_NOT_IMPLEMENTED;
    return NO;
}

- (void) registerForRemoteNotificationTypes:(UIRemoteNotificationType)types
{
    AP_NOT_IMPLEMENTED;
}

@end
