#import "Parse.h"

#import <UIKit/UIKit.h>

#import "GlueCommon.h"

@implementation Parse

struct JavaMethod {
    const char* name;
    const char* sig;
    jmethodID method;
};

static JavaMethod kInitialize = {
    "initialize", "(Landroid/content/Context;Ljava/lang/String;Ljava/lang/String;)V", NULL
};

static NSString* s_applicationId;
static NSString* s_clientKey;

+ (jclass) jniClass
{
    static jclass result = NULL;
    if (!result) {
        result = [[UIApplication sharedApplication] jniFindClass:@"com.parse.Parse"];
        NSAssert(result, @"Failed to find com.parse.Parse");
    }
    return result;
}

+ (void) maybeInitJavaMethod:(JavaMethod*) m
{
    if (!m->method) {
        NSLog(@"Initializing JNI method %s...", m->name);
        JNIEnv* env = [[UIApplication sharedApplication] jniEnv];
        m->method = env->GetStaticMethodID([self jniClass], m->name, m->sig);
        NSAssert(m->method, @"JNI method lookup failed!");
        NSLog(@"Initializing JNI method %s... Done.", m->name);
    }
}

+ (void)setApplicationId:(NSString *)applicationId clientKey:(NSString *)clientKey
{
    s_applicationId = applicationId;
    s_clientKey = clientKey;

    [Parse maybeInitJavaMethod:&kInitialize];

    JNIEnv* env = [[UIApplication sharedApplication] jniEnv];
    jclass clazz = [Parse jniClass];
    jobject context = [[UIApplication sharedApplication] jniContext];

    env->PushLocalFrame(2);
    jstring jApplicationId = env->NewStringUTF(applicationId.cString);
    jstring jClientKey = env->NewStringUTF(clientKey.cString);

    env->CallStaticVoidMethod(clazz, kInitialize.method, context, jApplicationId, jClientKey);

    env->PopLocalFrame(NULL);
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
