#import "UIApplication.h"

#import "GlueCommon.h"

@implementation UIApplication

static UIApplication* g_Application;

+ (UIApplication*) sharedApplication
{
    return g_Application;
}

- (NSString*) versionName
{
    GLUE_NOT_IMPLEMENTED;
    return @"VERSION_NAME";
}

- (int) versionCode
{
    GLUE_NOT_IMPLEMENTED;
    return -1;
}

- (id) init
{
    self = [super init];
    if (self) {
        NSAssert(!g_Application, @"Tried to init UIApplication twice");
        g_Application = self;
    }
    return self;
}

- (BOOL) canTweet
{
    GLUE_NOT_IMPLEMENTED;
    return NO;
}

- (void) tweet:(NSString*)text url:(NSString*)url image:(NSString*)image
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) quit
{
    GLUE_NOT_IMPLEMENTED;
}

- (JNIEnv*) jniEnv
{
    GLUE_NOT_IMPLEMENTED;
    return NULL;
}

- (jobject) jniContext
{
    GLUE_NOT_IMPLEMENTED;
    return NULL;
}

- (jclass) jniFindClass:(NSString*)name
{
    GLUE_NOT_IMPLEMENTED;
    return NULL;
}

- (void) parseInitWithApplicationId:(NSString*)applicationId clientKey:(NSString*)clientKey
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) parseCallFunction:(NSString*)function block:(PFIdResultBlock)block
{
    GLUE_NOT_IMPLEMENTED;
}

- (jobject) parseNewObject:(NSString*)className
{
    GLUE_NOT_IMPLEMENTED;
    return NULL;
}

- (void) parseObject:(jobject)obj addKey:(NSString*)key value:(id)value
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) parseObject:(jobject)obj saveWithBlock:(PFBooleanResultBlock)block
{
    GLUE_NOT_IMPLEMENTED;
}

- (jobject) parseNewQuery:(NSString*)className
{
    GLUE_NOT_IMPLEMENTED;
    return NULL;
}

- (void) parseQuery:(jobject)obj whereKey:(NSString*)key equalTo:(id)vaue
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) parseQuery:(jobject)obj findWithBlock:(PFArrayResultBlock)block
{
    GLUE_NOT_IMPLEMENTED;
}

- (jobject) gaiTrackerWithTrackingId:(NSString*)trackingId
{
    GLUE_NOT_IMPLEMENTED;
    return NULL;
}

- (jobject) gaiDefaultTracker
{
    GLUE_NOT_IMPLEMENTED;
    return NULL;
}

- (jobject) gaiEventWithCategory:(NSString *)category
                          action:(NSString *)action
                           label:(NSString *)label
                           value:(NSNumber *)value
{
    GLUE_NOT_IMPLEMENTED;
    return NULL;
}

- (void) gaiTracker:(jobject)tracker set:(NSString*)param value:(NSString*)value
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) gaiTracker:(jobject)tracker send:(jobject)params
{
    GLUE_NOT_IMPLEMENTED;
}

- (BOOL) isPartInstalled:(int)part
{
    GLUE_NOT_IMPLEMENTED;
    return NO;
}

- (void) openPart:(int)part
{
    GLUE_NOT_IMPLEMENTED;
}

@end