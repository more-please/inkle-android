#import "UIApplication.h"

#import "GlueCommon.h"

#import <Foundation/Foundation.h>

NSArray* NSSearchPathForDirectoriesInDomains(
    NSSearchPathDirectory directoryKey,
    NSSearchPathDomainMask domainMask,
    BOOL expandTilde)
{
    // Ignore all the stupid parameters and just return the documents dir.
    NSString* result = [UIApplication sharedApplication].documentsDir;
    return [NSArray arrayWithObjects:result, nil];
}

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

- (void) shareJourneyWithName:(NSString*)existingName block:(NameResultBlock)block
{
    GLUE_NOT_IMPLEMENTED;
    block(nil);
}

- (void) mailTo:(NSString*)to message:(NSString*)message attachment:(NSString*)path
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) quit
{
    GLUE_NOT_IMPLEMENTED;
}

#ifdef ANDROID

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

- (void) parseCallFunction:(NSString*)function parameters:(NSDictionary*)parameters block:(PFIdResultBlock)block
{
    GLUE_NOT_IMPLEMENTED;
}

- (jobject) parseNewObject:(NSString*)className
{
    GLUE_NOT_IMPLEMENTED;
    return NULL;
}

- (jobject) parseNewObject:(NSString*)className objectId:(NSString*)objectId
{
    GLUE_NOT_IMPLEMENTED;
    return NULL;
}

- (NSString*) parseObjectId:(jobject)obj
{
    GLUE_NOT_IMPLEMENTED;
    return nil;
}

- (void) parseObject:(jobject)obj addKey:(NSString*)key value:(id)value
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) parseObject:(jobject)obj removeKey:(NSString*)key
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) parseObject:(jobject)obj saveWithBlock:(PFBooleanResultBlock)block
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) parseObject:(jobject)obj saveEventuallyWithBlock:(PFBooleanResultBlock)block
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) parseObject:(jobject)obj fetchWithBlock:(PFObjectResultBlock)block
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) parseObject:(jobject)obj refreshWithBlock:(PFObjectResultBlock)block
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

- (void) parseEnableAutomaticUser
{
    GLUE_NOT_IMPLEMENTED;
}

- (jobject) parseCurrentUser;
{
    GLUE_NOT_IMPLEMENTED;
    return NULL;
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

#endif

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
