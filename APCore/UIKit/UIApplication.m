#import "UIApplication.h"

#import "GlueCommon.h"

#import <Foundation/Foundation.h>

#import <stdlib.h>
#import <stdio.h>

@implementation UIApplication

static UIApplication* g_Application;

+ (UIApplication*) sharedApplication
{
    return g_Application;
}

- (BOOL) needsInitialSetup
{
    return NO;
}

- (BOOL) isFullScreen
{
    GLUE_NOT_IMPLEMENTED;
    return NO;
}

- (void) setFullScreen:(BOOL)fullScreen
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) stayAwake
{
    GLUE_NOT_IMPLEMENTED;
}

- (NSString*) versionName
{
    GLUE_NOT_IMPLEMENTED;
    return @"VERSION_NAME";
}

- (NSString*) googleAnalyticsId
{
    GLUE_NOT_IMPLEMENTED;
    return @"GOOGLE_ANALYTICS_ID";
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
    exit(EXIT_SUCCESS);
}

- (void) lockQuit
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) unlockQuit
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) fatalError:(NSString*)message
{
    GLUE_NOT_IMPLEMENTED;
    fprintf(stderr, "FATAL ERROR: %s\n", message.UTF8String);
    abort();
}

#if 0

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

- (void) parseInitWithApplicationId:(NSString*)applicationId host:(NSString*)host
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

- (int) defaultPart
{
    GLUE_NOT_IMPLEMENTED;
    return 0;
}

- (void) addCrashReportPath:(NSString*)path description:(NSString*)desc
{
    GLUE_NOT_IMPLEMENTED;
}

@end
