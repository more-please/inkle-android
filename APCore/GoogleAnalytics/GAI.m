#import "GAI.h"

#import <UIKit/UIKit.h>

#import "GAITracker.h"
#import "GlueCommon.h"

@implementation GAI

+ (GAI*) sharedInstance
{
    return [[GAI alloc] init];
}

- (id<GAITracker>)trackerWithTrackingId:(NSString *)trackingId
{
#ifdef ANDROID
    jobject obj = [[UIApplication sharedApplication] gaiTrackerWithTrackingId:trackingId];
    return [[AP_GAITracker alloc] initWithObj:obj];
#else
    GLUE_NOT_IMPLEMENTED;
    return nil;
#endif
}

- (id<GAITracker>) defaultTracker
{
#ifdef ANDROID
    jobject obj = [[UIApplication sharedApplication] gaiDefaultTracker];
    return [[AP_GAITracker alloc] initWithObj:obj];
#else
    GLUE_NOT_IMPLEMENTED;
    return nil;
#endif
}

@end
