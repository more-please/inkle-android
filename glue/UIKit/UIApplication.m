#import "UIApplication.h"

#import "GlueCommon.h"

@implementation UIApplication

static UIApplication* g_Application;

+ (UIApplication*) sharedApplication
{
    return g_Application;
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

- (void) quit
{
    GLUE_NOT_IMPLEMENTED;
}

- (NSData*) getResource:(NSString*)path
{
    GLUE_NOT_IMPLEMENTED;
    return nil;
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

@end