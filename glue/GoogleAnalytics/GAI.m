#import "GAI.h"

#import "GlueCommon.h"

@implementation GAI

+ (GAI *)sharedInstance
{
    GLUE_NOT_IMPLEMENTED;
    return nil;
}

- (id<GAITracker>)trackerWithName:(NSString *)name
                       trackingId:(NSString *)trackingId
{
    GLUE_NOT_IMPLEMENTED;
    return nil;
}

- (id<GAITracker>)trackerWithTrackingId:(NSString *)trackingId
{
    GLUE_NOT_IMPLEMENTED;
    return nil;
}

- (void)removeTrackerByName:(NSString *)name
{
    GLUE_NOT_IMPLEMENTED;
}

- (void)dispatch
{
    GLUE_NOT_IMPLEMENTED;
}

@end
