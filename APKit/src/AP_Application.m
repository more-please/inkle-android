#import "AP_Application.h"

#import "AP_Check.h"
#import "NSObject+AP_PerformBlock.h"

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
    // AP_NOT_IMPLEMENTED;
}

- (UIInterfaceOrientation) statusBarOrientation
{
    CGSize s = [UIScreen mainScreen].bounds.size;
    return (s.width > s.height)
        ? UIInterfaceOrientationLandscapeLeft
        : UIInterfaceOrientationPortrait;
}

- (AP_Window*) keyWindow
{
    // Nasty! This is a hangover from the original version that
    // ran on iOS inside a GLKViewController...
    return (AP_Window*) _delegate.window.rootViewController;
}

- (void) performOnUiThread:(UiThreadBlock)block
{
    NSThread* caller = [NSThread currentThread];
    [self performBlock:^{
        [self performBlock:block() onThread:caller waitUntilDone:NO];
    } onThread:_uiThread waitUntilDone:NO];
}

- (void) performOnGameThread:(GameThreadBlock)block
{
    [self performBlock:block onThread:_gameThread waitUntilDone:NO];
}

@end
