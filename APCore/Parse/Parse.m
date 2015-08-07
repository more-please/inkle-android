#import "Parse.h"

#import <UIKit/UIKit.h>

#import "GlueCommon.h"

@implementation Parse

static NSString* s_applicationId;
static NSString* s_clientKey;

+ (void)setApplicationId:(NSString *)applicationId clientKey:(NSString *)clientKey
{
    s_applicationId = applicationId;
    s_clientKey = clientKey;
#ifdef ANDROID
    [[UIApplication sharedApplication] parseInitWithApplicationId:applicationId clientKey:clientKey];
#endif
}

+ (NSString *)getApplicationId
{
    return s_applicationId;
}

+ (NSString *)getClientKey
{
    return s_clientKey;
}

@end
