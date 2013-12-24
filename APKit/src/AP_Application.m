#import "AP_Application.h"

#import "AP_Check.h"

@implementation AP_Application

static AP_Application* g_Application;

+ (AP_Application*) sharedApplication
{
    return g_Application;
}

- (id) init
{
    self = [super init];
    if (self) {
        AP_CHECK(!g_Application, return nil);
        g_Application = self;
    }
    return self;
}

- (void) dealloc
{
    AP_CHECK(g_Application == self, return);
    g_Application = nil;
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
