#import "Parse.h"

#import <UIKit/UIKit.h>

#import "GlueCommon.h"

@implementation Parse

static NSString* s_applicationId;
static NSString* s_host;

+ (void)setApplicationId:(NSString *)applicationId host:(NSString*)host
{
    s_applicationId = applicationId;
    s_host = host;
#ifdef ANDROID
    [[UIApplication sharedApplication] parseInitWithApplicationId:applicationId host:host];
#endif
}

+ (NSString *)getApplicationId
{
    return s_applicationId;
}

+ (NSString *)getHost
{
    return s_host;
}

@end
