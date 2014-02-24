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

@end