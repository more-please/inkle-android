#import <Foundation/Foundation.h>
#import <APKit/APKit.h>
#import <PAK/PAK.h>

#import <jni.h>
#import <errno.h>
#import <unistd.h>

#import <EGL/egl.h>
#import <GLES2/gl2.h>

#import <android/log.h>
#import <android/sensor.h>
#import <android/asset_manager.h>
#import <android/asset_manager_jni.h>
#import <android/storage_manager.h>
#import <android_native_app_glue.h>

#import <ck/ck.h>
#import <ck/mixer.h>

#import <unicode/udata.h>
#import <unicode/uloc.h>

#include <client/linux/handler/exception_handler.h>
#include <client/linux/handler/minidump_descriptor.h>

#import "AppDelegate.h"

@interface ParseResult : NSObject
@property(nonatomic) int handle;
@property(nonatomic,strong) NSString* string;
@property(nonatomic) BOOL boolean;
@end

@implementation ParseResult
@end

@interface Main : AP_Application <PAK_Reader>
@property(nonatomic,readonly) BOOL active;
@property(nonatomic,readonly,strong) NSRunLoop* runLoop;
@property(nonatomic,readonly) int idleCount;
@end

static Main* g_Main;
static NSRunLoop* g_RunLoop;

typedef struct JavaMethod {
    const char* name;
    const char* sig;
    jmethodID method;
} JavaMethod;

static JavaMethod kGetDocumentsDir = {
    "getDocumentsDir", "()Ljava/lang/String;", NULL
};
static JavaMethod kGetPublicDocumentsDir = {
    "getPublicDocumentsDir", "()Ljava/lang/String;", NULL
};
static JavaMethod kGetExpansionFilePath = {
    "getExpansionFilePath", "()Ljava/lang/String;", NULL
};
static JavaMethod kGetPatchFilePath = {
    "getPatchFilePath", "()Ljava/lang/String;", NULL
};
static JavaMethod kGetScreenInfo = {
    "getScreenInfo", "()[F", NULL
};
static JavaMethod kPleaseFinish = {
    "pleaseFinish", "()V", NULL
};
static JavaMethod kOpenURL = {
    "openURL", "(Ljava/lang/String;)V", NULL
};
static JavaMethod kGetAssets = {
    "getAssets", "()Landroid/content/res/AssetManager;", NULL
};
static JavaMethod kFindClass = {
    "findClass", "(Ljava/lang/String;)Ljava/lang/Class;", NULL
};
static JavaMethod kParseInit = {
    "parseInit", "(Ljava/lang/String;Ljava/lang/String;)V", NULL
};
static JavaMethod kParseCallFunction = {
    "parseCallFunction", "(ILjava/lang/String;Ljava/lang/String;)V", NULL
};
static JavaMethod kParseNewObject = {
    "parseNewObject", "(Ljava/lang/String;)Lcom/parse/ParseObject;", NULL
};
static JavaMethod kParseNewObjectId = {
    "parseNewObjectId", "(Ljava/lang/String;Ljava/lang/String;)Lcom/parse/ParseObject;", NULL
};
static JavaMethod kParseAddKey = {
    "parseAddKey", "(Lcom/parse/ParseObject;Ljava/lang/String;Ljava/lang/Object;)V", NULL
};
static JavaMethod kParseSave = {
    "parseSave", "(ILcom/parse/ParseObject;)V", NULL
};
static JavaMethod kParseNewQuery = {
    "parseNewQuery", "(Ljava/lang/String;)Lcom/parse/ParseQuery;", NULL
};
static JavaMethod kParseWhereEqualTo = {
    "parseWhereEqualTo", "(Lcom/parse/ParseQuery;Ljava/lang/String;Ljava/lang/Object;)V", NULL
};
static JavaMethod kParseFind = {
    "parseFind", "(ILcom/parse/ParseQuery;)V", NULL
};
static JavaMethod kParseEnableAutomaticUser = {
    "parseEnableAutomaticUser", "()V", NULL
};
static JavaMethod kParseCurrentUser = {
    "parseCurrentUser", "()Lcom/parse/ParseUser;", NULL
};
static JavaMethod kGaiTrackerWithTrackingId = {
    "gaiTrackerWithTrackingId", "(Ljava/lang/String;)Lcom/google/analytics/tracking/android/Tracker;", NULL
};
static JavaMethod kBoxLong = {
    "boxLong", "(J)Ljava/lang/Long;", NULL
};
static JavaMethod kGaiEvent = {
    "gaiEvent", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/Long;)Ljava/util/Map;", NULL
};
static JavaMethod kGaiTrackerSet = {
    "gaiTrackerSet", "(Lcom/google/analytics/tracking/android/Tracker;Ljava/lang/String;Ljava/lang/String;)V", NULL
};
static JavaMethod kGaiTrackerSend = {
    "gaiTrackerSend", "(Lcom/google/analytics/tracking/android/Tracker;Ljava/util/Map;)V", NULL
};
static JavaMethod kIsCrappyDevice = {
    "isCrappyDevice", "()Z", NULL
};
static JavaMethod kHideStatusBar = {
    "hideStatusBar", "()V", NULL
};
static JavaMethod kIsPartInstalled = {
    "isPartInstalled", "(I)Z", NULL
};
static JavaMethod kOpenPart = {
    "openPart", "(I)V", NULL
};
static JavaMethod kVersionName = {
    "versionName", "()Ljava/lang/String;", NULL
};
static JavaMethod kVersionCode = {
    "versionCode", "()I", NULL
};
static JavaMethod kCanTweet = {
    "canTweet", "()Z", NULL
};
static JavaMethod kTweet = {
    "tweet", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V", NULL
};
static JavaMethod kMailTo = {
    "mailTo", "(Ljava/lang/String;Ljava/lang/String;)V", NULL
};
static JavaMethod kGetLocale = {
    "getLocale", "()Ljava/lang/String;", NULL
};

static void initBreakpad(JNIEnv*, jobject, jstring);
static void parseCallResult(JNIEnv*, jobject, jint, jstring);
static void parseSaveResult(JNIEnv*, jobject, jint, jboolean);
static void parseFindResult(JNIEnv*, jobject, jint, jstring);

static JNINativeMethod kNatives[] = {
    { "initBreakpad", "(Ljava/lang/String;)V", (void *)&initBreakpad},
    { "parseCallResult", "(ILjava/lang/String;)V", (void *)&parseCallResult},
    { "parseSaveResult", "(IZ)V", (void *)&parseSaveResult},
    { "parseFindResult", "(ILjava/lang/String;)V", (void *)&parseFindResult},
};

static google_breakpad::ExceptionHandler* exceptionHandler;

static bool breakback(
    const google_breakpad::MinidumpDescriptor& descriptor,
    void* context,
    bool succeeded) {
  NSLog(@"Breakpad dump path: %s\n", descriptor.path());
  return succeeded;
}

void initBreakpad(JNIEnv* env, jobject obj, jstring filepath) {
#ifndef DEBUG
    const char *path = env->GetStringUTFChars(filepath, 0);
    google_breakpad::MinidumpDescriptor descriptor(path);
    exceptionHandler = new google_breakpad::ExceptionHandler(descriptor, NULL, breakback, NULL, true, -1);
#endif
}

extern "C" {
JNIEXPORT void JNICALL Java_com_inkle_sorcery_SorceryActivity_initBreakpad(
        JNIEnv* env, jobject obj, jstring filepath) {
    initBreakpad(env, obj, filepath);
}
} // "C"

static int _NSLog_fd = -1;

static double timeInSeconds() {
    struct timespec t;
    int result = clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + (double) t.tv_nsec / 1000000000.0;
}

static void NSLog_handler(NSString* message) {
    static double start = 0.0;
    if (start == 0.0) {
        start = timeInSeconds();
    }
    double dt = timeInSeconds() - start;
    message = [NSString stringWithFormat:@"%.2lf %@", dt, message];
    __android_log_print(ANDROID_LOG_INFO, "NSLog", "%s", message.UTF8String);
    message = [message stringByAppendingString:@"\n"];
    write(_NSLog_fd, message.UTF8String, message.length);
}

@implementation Main {
    struct android_app* _android;

    AAssetManager* _assetManager;
    NSString* _obbPath;

    JavaVM* _vm;
    JNIEnv* _env;
    jclass _class;
    jobject _instance;

    EGLDisplay _display;
    EGLConfig _config;
    EGLContext _context;
    EGLSurface _surface; // This can change across suspend/resume

    BOOL _inForeground;
    NSDate* _autoQuitTime;

    NSMutableDictionary* _touches; // Map of ID -> UITouch

    NSMutableDictionary* _parseCallBlocks; // Map of int -> PFStringResultBlock
    NSMutableDictionary* _parseSaveBlocks; // Map of int -> PFBooleanResultBlock
    NSMutableDictionary* _parseFindBlocks; // Map of int -> PFArrayResultBlock

    jobject _gaiDefaultTracker;
    NSArray* _pakNamesCache;
}

- (id) initWithAndroidApp:(struct android_app*)android
{
    self = [super init];
    if (self) {
        AP_CHECK(!g_Main, return nil);
        g_Main = self;
        g_RunLoop = [NSRunLoop currentRunLoop];

        _android = android;
        _vm = _android->activity->vm;
        AP_CHECK(_vm, return nil);

        // Initialize JVM on this thread.
        JavaVMAttachArgs args = {
            JNI_VERSION_1_4,
            "Sorcery",
            NULL
        };
        jint result = _vm->AttachCurrentThread(&_env, &args);
        AP_CHECK(result == JNI_OK, return nil);
        AP_CHECK(_env, return nil);

        // Initialize Cricket Audio
        CkConfig config(_env, _android->activity->clazz);
        config.useJavaAudio = true; // OpenSLES is totally broken.
        // Nice big audio buffers, to prevent any glitches.
        config.audioUpdateMs = 20;
        config.streamBufferMs = 2000;
        config.streamFileUpdateMs = 400;
        int success = CkInit(&config);
        AP_CHECK(success, return nil);

        // Get SorceryActivity and its methods.
        _instance = _env->NewGlobalRef(_android->activity->clazz);
        AP_CHECK(_instance, return nil);

        _class = _env->GetObjectClass(_instance);
        AP_CHECK(_class, return nil);

        _env->RegisterNatives(_class, kNatives, sizeof(kNatives) / sizeof(kNatives[0]));

        self.documentsDir = [self javaStringMethod:&kGetDocumentsDir];
        self.publicDocumentsDir = [self javaStringMethod:&kGetPublicDocumentsDir];
        [NSUserDefaults setDocumentsDir:self.documentsDir];

        // Send NSLog to a file
        NSString* logfile = [self.documentsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld.log", time(NULL)]];
        _NSLog_fd = open(logfile.UTF8String, O_CREAT | O_WRONLY | O_APPEND, 644);
        NSAssert(_NSLog_fd >= 0, @"Error opening log file: %s", strerror(errno));

        NSLog(@"Logging to: %@", logfile);
        _NSLog_printf_handler = NSLog_handler;

        _touches = [NSMutableDictionary dictionary];

        // Check whether we're running on a low-end device.
        if ([self javaBoolMethod:&kIsCrappyDevice]) {
            NSLog(@"*** Running on a low-end device.");
            self.isCrappyDevice = YES;
        }

        // Initialize non-OBB assets.
        _assetManager = [self getAssets];

        // Locate the OBB.
        _obbPath = [self javaStringMethod:&kGetExpansionFilePath];
        AP_CHECK(_obbPath, return nil);

        _parseCallBlocks = [NSMutableDictionary dictionary];
        _parseSaveBlocks = [NSMutableDictionary dictionary];
        _parseFindBlocks = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void) dealloc
{
    [self teardownGL];
    [self teardownJava];
    g_Main = nil;
}

- (void) maybeAutoQuit
{
    NSDate* now = [NSDate date];
    if (_autoQuitTime && [now laterDate:_autoQuitTime] == now) {
        NSLog(@"*** Sorcery! is idle in the background. Auto-quitting to save memory.");
        _autoQuitTime = nil;
        [self quit];
    }
}

- (void) quit
{
    [self javaVoidMethod:&kPleaseFinish];
}

- (void) teardownJava
{
    if (_env) {
        NSLog(@"Detaching from JNI");
        [self javaVoidMethod:&kPleaseFinish];
        _vm->DetachCurrentThread();
        _vm = NULL;
        _env = NULL;
    }
}

- (NSArray*) pakNames
{
    if (!_pakNamesCache) {
        // There's no API for iterating over asset directories.
        // We'll just have to hard-code the directory names, bah!
        const char* dirNames[] = {
            "AudioLoops",
            "AudioShuffles",
            "CommonAudioLoops",
            "CommonAudioShuffles",
            NULL
        };
        NSMutableArray* cache = [NSMutableArray array];
        for (int i = 0; dirNames[i]; ++i) {
            AAssetDir* d = AAssetManager_openDir(_assetManager, dirNames[i]);
            if (!d) {
                continue;
            }
            NSString* dirName = [NSString stringWithCString:dirNames[i]];
            const char* c = AAssetDir_getNextFileName(d);
            for ( ; c; c = AAssetDir_getNextFileName(d)) {
                NSString* s = [NSString stringWithCString:c];
                s = [dirName stringByAppendingPathComponent:s];
                [cache addObject:s];
            }
            AAssetDir_close(d);
        }
        _pakNamesCache = cache;
    }
    return _pakNamesCache;
}


- (PAK_Item*) pakItem:(NSString*)path
{
    AAsset* asset = AAssetManager_open(_assetManager, path.UTF8String, AASSET_MODE_STREAMING);
    if (!asset) {
        NSLog(@"Failed to open asset: %@", path);
        return nil;
    }

    off_t size = AAsset_getLength(asset);
    NSMutableData* data = [NSMutableData dataWithLength:size];
    char* ptr = (char*) data.bytes;
    int remaining = size;
    while (remaining > 0) {
        int bytes = AAsset_read(asset, ptr, remaining);
        ptr += bytes;
        remaining -= bytes;
        if (bytes == 0) {
            // EOF
            break;
        }
        if (bytes < 0) {
            NSLog(@"I/O error reading asset: %@", path);
            break;
        }
    }
    if (remaining != 0) {
        NSLog(@"Failed to read asset: %@", path);
        data = nil;
    }
    AAsset_close(asset);

    if (data) {
        return [[PAK_Item alloc] initWithName:path path:path isAsset:YES offset:0 length:data.length data:data];
    } else {
        return nil;
    }
}

- (BOOL) inForeground
{
    return _inForeground;
}

- (BOOL) canDraw
{
    return _surface != EGL_NO_SURFACE;
}

- (void) maybeInitJavaMethod:(JavaMethod*)m
{
    if (!m->method) {
//        NSLog(@"Initializing JNI method %s...", m->name);
        m->method = _env->GetMethodID(_class, m->name, m->sig);
        NSAssert(m->method, @"JNI method lookup failed!");
//        NSLog(@"Initializing JNI method %s... Done.", m->name);
    }
}

- (void) javaVoidMethod:(JavaMethod*)m
{
    [self maybeInitJavaMethod:m];
    _env->CallVoidMethod(_instance, m->method);
}

- (void) javaVoidMethod:(JavaMethod*)m withString:(NSString*)s
{
    [self maybeInitJavaMethod:m];

    _env->PushLocalFrame(16);
    jstring jstr = _env->NewStringUTF(s.UTF8String);
    _env->CallVoidMethod(_instance, m->method, jstr);

    _env->PopLocalFrame(NULL);

}

- (BOOL) javaBoolMethod:(JavaMethod*)m
{
    [self maybeInitJavaMethod:m];
    jboolean result = _env->CallBooleanMethod(_instance, m->method);
    return result;
}

- (int) javaIntMethod:(JavaMethod*)m
{
    [self maybeInitJavaMethod:m];
    jint result = _env->CallIntMethod(_instance, m->method);
    return result;
}

- (NSString*) javaStringMethod:(JavaMethod*)m
{
    [self maybeInitJavaMethod:m];

    _env->PushLocalFrame(16);

    jstring str = (jstring) _env->CallObjectMethod(_instance, m->method);
    AP_CHECK(str, return nil);
    const char* c = _env->GetStringUTFChars(str, NULL);
    NSString* result = [NSString stringWithCString:c];
    _env->ReleaseStringUTFChars(str, c);

    _env->PopLocalFrame(NULL);
    return result;
}

- (BOOL) javaFloatsMethod:(JavaMethod*)m ptr:(float*)ptr size:(size_t)size
{
    [self maybeInitJavaMethod:m];

    _env->PushLocalFrame(16);

    jfloatArray arr = (jfloatArray) _env->CallObjectMethod(_instance, m->method);
    if (_env->ExceptionOccurred()) {
        _env->ExceptionDescribe();
        _env->ExceptionClear();
        return NO;
    }
    AP_CHECK(arr, return NO);
    AP_CHECK(_env->GetArrayLength(arr) == size, return NO);
    jfloat* f = _env->GetFloatArrayElements(arr, NULL);
    for (int i = 0; i < size; ++i) {
        ptr[i] = f[i];
    }
    _env->ReleaseFloatArrayElements(arr, f, 0);

    _env->PopLocalFrame(NULL);
    return YES;
}

- (JNIEnv*) jniEnv
{
    return _env;
}

- (jobject) jniContext
{
    return _instance;
}

- (jclass) jniFindClass:(NSString*)name
{
    [self maybeInitJavaMethod:&kFindClass];

    _env->PushLocalFrame(16);
    jstring str = _env->NewStringUTF(name.UTF8String);
    jclass result = (jclass) _env->CallObjectMethod(_instance, kFindClass.method, str);
    result = (jclass) _env->NewGlobalRef(result);

    _env->PopLocalFrame(NULL);
    return result;
}

- (NSString*) versionName
{
    return [self javaStringMethod:&kVersionName];
}

- (int) versionCode
{
    return [self javaIntMethod:&kVersionCode];
}

- (void) parseInitWithApplicationId:(NSString*)applicationId clientKey:(NSString*)clientKey
{
    [self maybeInitJavaMethod:&kParseInit];

    _env->PushLocalFrame(16);
    jstring jApplicationId = _env->NewStringUTF(applicationId.UTF8String);
    jstring jClientKey = _env->NewStringUTF(clientKey.UTF8String);

    _env->CallVoidMethod(_instance, kParseInit.method, jApplicationId, jClientKey);

    _env->PopLocalFrame(NULL);
}

- (void) parseCallFunction:(NSString*)function parameters:(NSDictionary*)params block:(PFIdResultBlock)block
{
    static int handle = 0;
    ++handle;
    if (block) {
        [_parseCallBlocks setObject:block forKey:@(handle)];
    }

    [self maybeInitJavaMethod:&kParseCallFunction];

    _env->PushLocalFrame(16);
    jstring jFunction = _env->NewStringUTF(function.UTF8String);
    jobject jParams = [self jsonEncode:params];

    _env->CallVoidMethod(_instance, kParseCallFunction.method, handle, jFunction, jParams);

    _env->PopLocalFrame(NULL);
}

static void parseCallResult(JNIEnv* env, jobject obj, jint i, jstring s) {
    ParseResult* result = [[ParseResult alloc] init];
    result.handle = i;
    if (s) {
        const char* c = env->GetStringUTFChars(s, NULL);
        result.string = [NSString stringWithCString:c];
        env->ReleaseStringUTFChars(s, c);
    }

    // NSLog(@"Posting parseCallResult handle:%d string:%@", result.handle, result.string);
    [g_Main performSelectorOnMainThread:@selector(parseCallResult:)
        withObject:result
        waitUntilDone:NO];
}

- (void) parseCallResult:(ParseResult*)result
{
    // NSLog(@"parseCallResult handle:%d string:%@", result.handle, result.string);
    PFIdResultBlock block = [_parseCallBlocks objectForKey:@(result.handle)];
    if (block) {
        NSError* error = nil;
        id json = [self jsonDecode:result error:&error];
        block(json, error);
    }
    [_parseCallBlocks removeObjectForKey:@(result.handle)];
}

- (void) parseObject:(jobject)obj saveWithBlock:(PFBooleanResultBlock)block
{
    static int handle = 0;
    ++handle;
    if (block) {
        [_parseSaveBlocks setObject:block forKey:@(handle)];
    }

    [self maybeInitJavaMethod:&kParseSave];
    _env->CallVoidMethod(_instance, kParseSave.method, handle, obj);
}

static void parseSaveResult(JNIEnv* env, jobject obj, jint i, jboolean b) {
    ParseResult* result = [[ParseResult alloc] init];
    result.handle = i;
    result.boolean = b;

    // NSLog(@"Posting parseSaveResult handle:%d result:%d", result.handle, result.boolean);
    [g_Main performSelectorOnMainThread:@selector(parseSaveResult:)
        withObject:result
        waitUntilDone:NO];
}

- (void) parseSaveResult:(ParseResult*)result
{
    // NSLog(@"parseSaveResult handle:%d value:%d", result.handle, result.boolean);
    PFBooleanResultBlock block = [_parseSaveBlocks objectForKey:@(result.handle)];
    if (block) {
        NSError* error = result.boolean ? nil : [NSError errorWithDomain:@"Parse" code:-1 userInfo:nil];
        block(result.boolean, nil);
    }
    [_parseSaveBlocks removeObjectForKey:@(result.handle)];
}

- (jobject) parseNewObject:(NSString*)className
{
    [self maybeInitJavaMethod:&kParseNewObject];

    _env->PushLocalFrame(16);
    jstring jName = _env->NewStringUTF(className.UTF8String);

    jobject result = _env->CallObjectMethod(_instance, kParseNewObject.method, jName);
    result = _env->NewGlobalRef(result);

    _env->PopLocalFrame(NULL);
    return result;
}

- (jobject) parseNewObject:(NSString*)className objectId:(NSString*)objectId
{
    [self maybeInitJavaMethod:&kParseNewObjectId];

    _env->PushLocalFrame(16);
    jstring jName = _env->NewStringUTF(className.UTF8String);
    jstring jId = _env->NewStringUTF(objectId.UTF8String);

    jobject result = _env->CallObjectMethod(_instance, kParseNewObjectId.method, jName, jId);
    result = _env->NewGlobalRef(result);

    _env->PopLocalFrame(NULL);
    return result;
}

- (jobject) jsonEncode:(id)value
{
    if (!value) {
        return NULL;
    }
    if ([value isKindOfClass:[PFObject class]]) {
        // Send PFObjects without any encoding
        PFObject* pf = (PFObject*) value;
        return pf.jobj;
    }

    NSString* valueStr;
    if ([value isKindOfClass:[NSString class]]) {
        // If it's a string, send it directly
        valueStr = (NSString*)value;
    } else {
        // Otherwise, encode as JSON.
        NSError* error = nil;
        NSData* valueData = [NSJSONSerialization dataWithJSONObject:value options:0 error:&error];
        if (error) {
            NSLog(@"JSON writer error: %@", error);
            return NULL;
        }
        valueStr = [[NSString alloc] initWithData:valueData encoding:NSUTF8StringEncoding];
    }
    return _env->NewStringUTF(valueStr.UTF8String);
}

- (id) jsonDecode:(ParseResult*)result error:(NSError**)error
{
    if (result.string) {
        NSData* data = [result.string dataUsingEncoding:NSUTF8StringEncoding];
        *error = nil;
        return [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    } else {
        *error = [NSError errorWithDomain:@"Parse" code:-1 userInfo:nil];
        return nil;
    }
}

- (void) parseObject:(jobject)obj addKey:(NSString*)key value:(id)value
{
    [self maybeInitJavaMethod:&kParseAddKey];

    _env->PushLocalFrame(16);
    jstring jKey = _env->NewStringUTF(key.UTF8String);
    jobject jValue = [self jsonEncode:value];

    _env->CallVoidMethod(_instance, kParseAddKey.method, obj, jKey, jValue);

    _env->PopLocalFrame(NULL);
}

- (jobject) parseNewQuery:(NSString*)className
{
    [self maybeInitJavaMethod:&kParseNewQuery];

    _env->PushLocalFrame(16);
    jstring jName = _env->NewStringUTF(className.UTF8String);

    jobject result = _env->CallObjectMethod(_instance, kParseNewQuery.method, jName);
    result = _env->NewGlobalRef(result);

    _env->PopLocalFrame(NULL);
    return result;
}

- (void) parseQuery:(jobject)obj whereKey:(NSString*)key equalTo:(id)value
{
    [self maybeInitJavaMethod:&kParseWhereEqualTo];

    _env->PushLocalFrame(16);
    jstring jKey = _env->NewStringUTF(key.UTF8String);
    jobject jValue = [self jsonEncode:value];

    _env->CallVoidMethod(_instance, kParseWhereEqualTo.method, obj, jKey, jValue);

    _env->PopLocalFrame(NULL);
}

- (void) parseQuery:(jobject)obj findWithBlock:(PFArrayResultBlock)block
{
    static int handle = 0;
    ++handle;
    if (block) {
        [_parseFindBlocks setObject:block forKey:@(handle)];
    }

    [self maybeInitJavaMethod:&kParseFind];
    _env->CallVoidMethod(_instance, kParseFind.method, handle, obj);
}

static void parseFindResult(JNIEnv* env, jobject obj, jint i, jstring s) {
    ParseResult* result = [[ParseResult alloc] init];
    result.handle = i;
    if (s) {
        const char* c = env->GetStringUTFChars(s, NULL);
        result.string = [NSString stringWithCString:c];
        env->ReleaseStringUTFChars(s, c);
    }

    // NSLog(@"Posting parseFindResult handle:%d string:%@", result.handle, result.string);
    [g_Main performSelectorOnMainThread:@selector(parseFindResult:)
        withObject:result
        waitUntilDone:NO];
}

- (void) parseFindResult:(ParseResult*)result
{
    // NSLog(@"parseFindResult handle:%d string:%@", result.handle, result.string);
    PFArrayResultBlock block = [_parseFindBlocks objectForKey:@(result.handle)];
    if (block) {
        NSError* error = nil;
        id json = [self jsonDecode:result error:&error];
        block(json, error);
    }
    [_parseFindBlocks removeObjectForKey:@(result.handle)];
}

- (void) parseEnableAutomaticUser
{
    [self javaVoidMethod:&kParseEnableAutomaticUser];
}

- (jobject) parseCurrentUser
{
    [self maybeInitJavaMethod:&kParseCurrentUser];

    _env->PushLocalFrame(16);

    jobject result = _env->CallObjectMethod(_instance, kParseCurrentUser.method);
    result = _env->NewGlobalRef(result);

    _env->PopLocalFrame(NULL);
    return result;
}

- (jobject) gaiTrackerWithTrackingId:(NSString*)trackingId
{
    [self maybeInitJavaMethod:&kGaiTrackerWithTrackingId];

    _env->PushLocalFrame(16);
    jstring jName = _env->NewStringUTF(trackingId.UTF8String);

    jobject result = _env->CallObjectMethod(_instance, kGaiTrackerWithTrackingId.method, jName);
    result = _env->NewGlobalRef(result);
    if (!_gaiDefaultTracker) {
        _gaiDefaultTracker = result;
    }

    _env->PopLocalFrame(NULL);
    return result;
}

- (jobject) gaiDefaultTracker
{
    return _gaiDefaultTracker;
}

- (jobject) gaiEventWithCategory:(NSString *)category
                          action:(NSString *)action
                           label:(NSString *)label
                           value:(NSNumber *)value
{
    [self maybeInitJavaMethod:&kBoxLong];
    [self maybeInitJavaMethod:&kGaiEvent];
    _env->PushLocalFrame(16);

    jstring jCategory = _env->NewStringUTF(category.UTF8String);
    jstring jAction = _env->NewStringUTF(label.UTF8String);
    jstring jLabel = _env->NewStringUTF(action.UTF8String);
    jobject jValue = NULL;
    if (value) {
        jValue = _env->CallObjectMethod(_instance, kBoxLong.method, (jlong) value.longLongValue);
    }

    jobject result = _env->CallObjectMethod(_instance, kGaiEvent.method, jCategory, jAction, jLabel, jValue);
    result = _env->NewGlobalRef(result);

    _env->PopLocalFrame(NULL);
    return result;
}

- (void) gaiTracker:(jobject)tracker set:(NSString*)param value:(NSString*)value
{
    [self maybeInitJavaMethod:&kGaiTrackerSet];
    _env->PushLocalFrame(16);

    jstring jParam = _env->NewStringUTF(param.UTF8String);
    jstring jValue = _env->NewStringUTF(value.UTF8String);
    _env->CallVoidMethod(_instance, kGaiTrackerSet.method, tracker, jParam, jValue);

    _env->PopLocalFrame(NULL);
}

- (void) gaiTracker:(jobject)tracker send:(jobject)params
{
    [self maybeInitJavaMethod:&kGaiTrackerSend];
    _env->PushLocalFrame(16);

    _env->CallVoidMethod(_instance, kGaiTrackerSend.method, tracker, params);
    _env->DeleteGlobalRef(params);

    _env->PopLocalFrame(NULL);
}

- (AAssetManager*) getAssets
{
    [self maybeInitJavaMethod:&kGetAssets];

    _env->PushLocalFrame(16);

    jobject obj = _env->CallObjectMethod(_instance, kGetAssets.method);
    obj = _env->NewGlobalRef(obj);
    AAssetManager* result = AAssetManager_fromJava(_env, obj);
    if (!result) {
        NSLog(@"Failed to open AssetManager!");
        abort();
    }

    _env->PopLocalFrame(NULL);
    return result;
}

- (BOOL) openURL:(NSURL*)url
{
    NSString* s = url.absoluteString;
    NSLog(@"Opening URL: %@", s);
    [self javaVoidMethod:&kOpenURL withString:s];
    return YES;
}

- (BOOL) isPartInstalled:(int)part
{
    [self maybeInitJavaMethod:&kIsPartInstalled];
    jboolean result = _env->CallBooleanMethod(_instance, kIsPartInstalled.method, part);
    return result;
}

- (void) openPart:(int)part
{
    [self maybeInitJavaMethod:&kOpenPart];
    _env->CallVoidMethod(_instance, kOpenPart.method, part);
}

- (BOOL) canTweet
{
    return [self javaBoolMethod:&kCanTweet];
}

- (void) tweet:(NSString*)text url:(NSString*)url image:(NSString*)image
{
    [self maybeInitJavaMethod:&kTweet];

    _env->PushLocalFrame(16);
    jstring s1 = text ? _env->NewStringUTF(text.UTF8String) : NULL;
    jstring s2 = url ? _env->NewStringUTF(url.UTF8String) : NULL;
    jstring s3 = image ? _env->NewStringUTF(image.UTF8String) : NULL;
    _env->CallVoidMethod(_instance, kTweet.method, s1, s2, s3);

    _env->PopLocalFrame(NULL);
}

- (void) mailTo:(NSString*)to attachment:(NSString*)path
{
    [self maybeInitJavaMethod:&kMailTo];

    _env->PushLocalFrame(16);
    jstring s1 = to ? _env->NewStringUTF(to.UTF8String) : NULL;
    jstring s2 = path ? _env->NewStringUTF(path.UTF8String) : NULL;
    _env->CallVoidMethod(_instance, kMailTo.method, s1, s2);

    _env->PopLocalFrame(NULL);
}

- (void) maybeInitApp
{
    if (_display == EGL_NO_DISPLAY) {
        // No display yet.
        return;
    }
    if (self.delegate) {
        // Already initialized
        return;
    }

    PAK* pak;

    AAsset* pakAsset = AAssetManager_open(_assetManager, "sorcery.ogg", AASSET_MODE_BUFFER);
    if (pakAsset) {
        NSLog(@"Mapping OBB...");
        if (AAsset_isAllocated(pakAsset)) {
            NSLog(@"*** WARNING, game data is allocated (not mmapped) ***");
            NSLog(@"This is wasting a lot of memory.");
        }

        void* ptr = const_cast<void*>(AAsset_getBuffer(pakAsset));
        NSAssert(ptr, @"AAsset_getBuffer failed!");

        off_t size = AAsset_getLength(pakAsset);
        NSAssert(size, @"AAsset_getLength failed!");

        NSData* data = [NSData dataWithBytesNoCopy:ptr length:size freeWhenDone:NO];
        NSAssert(data, @"dataWithBytesNoCopy failed!");

        pak = [PAK pakWithAsset:@"sorcery.ogg" data:data];

    } else {
        // Using Google Play-style expansion files.
        // This means there may be a patch file.
        NSString* patch = [self javaStringMethod:&kGetPatchFilePath];
        if (patch) {
            pak = [PAK pakWithMemoryMappedFile:patch];
            [PAK_Search add:pak];
        }

        pak = [PAK pakWithMemoryMappedFile:_obbPath];

        // A cheat: assume all the sounds are in the OBB, so we
        // don't have to bother checking assets (which are very slow).
        _pakNamesCache = [NSArray array];
    }

    NSAssert(pak, @"Can't find .pak file");
    [PAK_Search add:pak];

    // TODO: could potentially look for a patch file too

    // Add ourselves as a backup resource bundle (APK assets)
    [PAK_Search add:self];

    NSLog(@"Let's get started!");
    AppDelegate* sorcery = [[AppDelegate alloc] init];
    self.delegate = sorcery;

    // Splash screen

    [self updateScreenSize];

    AP_Window* window = [[AP_Window alloc] init];
    sorcery.window = [[Real_UIWindow alloc] init];
    sorcery.window.rootViewController = window; // Err, yes, well

    AP_Image* logo = [AP_Image imageNamed:@"80-days-logo"];
    logo = [logo imageWithWidth:[AP_Window widthForIPhone:150 iPad:250]];

    AP_ImageView* view = [[AP_ImageView alloc] initWithImage:logo];
    view.frame = [[UIScreen mainScreen] bounds];
    view.contentMode = UIViewContentModeCenter;
    view.autoresizingMask = UIViewAutoresizing(-1);

    AP_ViewController* controller = [[AP_ViewController alloc] init];
    controller.view = view;
    window.rootViewController = controller;

    [self updateGL:YES];

    // Without this, the splash screen gets leaked...?
    window.rootViewController = nil;

    NSLog(@"Initializing ICU...");
    NSData* icuDat = [NSBundle dataForResource:@"icudt51l.dat" ofType:nil];
    UErrorCode icuErr = U_ZERO_ERROR;
    udata_setCommonData(icuDat.bytes, &icuErr);
    NSAssert(U_SUCCESS(icuErr), @"ICU error: %d", icuErr);

    NSString* locale = [self javaStringMethod:&kGetLocale];
    NSLog(@"Locale: %@", locale);
    uloc_setDefault([locale cStringUsingEncoding:NSUTF8StringEncoding], &icuErr);
    NSAssert(U_SUCCESS(icuErr), @"ICU error: %d", icuErr);

    // Finally, start the game!

    NSLog(@"Starting game...");
    NSDictionary* options = [NSDictionary dictionary];
    [self.delegate application:self didFinishLaunchingWithOptions:options];
}

typedef struct {
    EGLint attr;
    const char* name;
} EGLattr;

#define ATTR(a) { a, #a }

static EGLattr EGLattrs[] = {
    ATTR(EGL_BUFFER_SIZE),
    ATTR(EGL_ALPHA_SIZE),
    ATTR(EGL_BLUE_SIZE),
    ATTR(EGL_GREEN_SIZE),
    ATTR(EGL_RED_SIZE),
    ATTR(EGL_DEPTH_SIZE),
    ATTR(EGL_STENCIL_SIZE),
    ATTR(EGL_CONFIG_CAVEAT),
    ATTR(EGL_CONFIG_ID),
    ATTR(EGL_LEVEL),
    ATTR(EGL_MAX_PBUFFER_HEIGHT),
    ATTR(EGL_MAX_PBUFFER_PIXELS),
    ATTR(EGL_MAX_PBUFFER_WIDTH),
    ATTR(EGL_NATIVE_RENDERABLE),
    ATTR(EGL_NATIVE_VISUAL_ID),
    ATTR(EGL_NATIVE_VISUAL_TYPE),
    ATTR(EGL_SAMPLES),
    ATTR(EGL_SAMPLE_BUFFERS),
    ATTR(EGL_SURFACE_TYPE),
    ATTR(EGL_TRANSPARENT_TYPE),
    ATTR(EGL_TRANSPARENT_BLUE_VALUE),
    ATTR(EGL_TRANSPARENT_GREEN_VALUE),
    ATTR(EGL_TRANSPARENT_RED_VALUE),
    ATTR(EGL_BIND_TO_TEXTURE_RGB),
    ATTR(EGL_BIND_TO_TEXTURE_RGBA),
    ATTR(EGL_MIN_SWAP_INTERVAL),
    ATTR(EGL_MAX_SWAP_INTERVAL),
    ATTR(EGL_LUMINANCE_SIZE),
    ATTR(EGL_ALPHA_MASK_SIZE),
    ATTR(EGL_COLOR_BUFFER_TYPE),
    ATTR(EGL_RENDERABLE_TYPE),
    ATTR(EGL_CONFORMANT),
    ATTR(EGL_NONE),
};

- (void) dumpConfig:(EGLConfig)c
{
    for (int i = 0; EGLattrs[i].attr != EGL_NONE; ++i) {
        EGLattr& a = EGLattrs[i];
        EGLint value;
        eglGetConfigAttrib(_display, c, a.attr, &value);
        NSLog(@"%s: %d", a.name, value);
    }
}

- (void) maybeInitGL
{
    if (_display == EGL_NO_DISPLAY) {
        NSLog(@"Initializing EGL display...");

        _display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
        eglInitialize(_display, 0, 0);

        const EGLint attribs[] = {
                EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
                EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
                // The original Kindle Fire gives us a config with broken
                // alpha if we request 24-bit colour. However, some other
                // devices give us 16-bit configs if we don't specify any
                // constraints! Therefore, request 16-bit colour at a minimum
                // (if there's a 32-bit config it should be sorted first).
                EGL_BLUE_SIZE, 5,
                EGL_GREEN_SIZE, 6,
                EGL_RED_SIZE, 5,
                EGL_NONE
        };

        EGLint numConfigs;

//        static EGLConfig configs[500];
//        eglChooseConfig(_display, attribs, configs, 500, &numConfigs);
//        for (int i = 0; i < numConfigs; ++i) {
//            NSLog(@"EGL config %d of %d:", i, numConfigs);
//            [self dumpConfig:configs[i]];
//            NSLog(@"----");
//        }

        eglChooseConfig(_display, attribs, &_config, 1, &numConfigs);
        [self dumpConfig:_config];

        const EGLint contextAttribs[] = {
            EGL_CONTEXT_CLIENT_VERSION, 2,
            EGL_NONE
        };

        _context = eglCreateContext(_display, _config, NULL, contextAttribs);
    }
}

- (void) maybeInitSurface
{
    if (_surface == EGL_NO_SURFACE) {
        [self maybeInitGL];

        NSLog(@"Initializing EGL surface...");

        // EGL_NATIVE_VISUAL_ID is an attribute of the EGLConfig that is
        // guaranteed to be accepted by ANativeWindow_setBuffersGeometry().
        // As soon as we picked a EGLConfig, we can safely reconfigure the
        // ANativeWindow buffers to match, using EGL_NATIVE_VISUAL_ID.
        EGLint format;
        eglGetConfigAttrib(_display, _config, EGL_NATIVE_VISUAL_ID, &format);
        ANativeWindow_setBuffersGeometry(_android->window, 0, 0, format);

        _surface = eglCreateWindowSurface(_display, _config, _android->window, NULL);

        if (eglMakeCurrent(_display, _surface, _surface, _context) == EGL_FALSE) {
            NSLog(@"Initializing EGL surface... Failed!");
            abort();
        }
    }

    [self updateScreenSize];
}

- (void) updateScreenSize
{
    AP_CHECK(_display, return);
    // eglQuerySurface(_display, _surface, EGL_WIDTH, &w);
    // eglQuerySurface(_display, _surface, EGL_HEIGHT, &h);

    float f[9];
    if ([self javaFloatsMethod:&kGetScreenInfo ptr:f size:9]) {
        float scale = f[0];

        CGRect bounds;
        bounds.origin.x = f[1] / scale;
        bounds.origin.y = f[2] / scale;
        bounds.size.width = f[3] / scale;
        bounds.size.height = f[4] / scale;

        CGRect appFrame;
        appFrame.origin.x = f[5] / scale;
        appFrame.origin.y = f[6] / scale;
        appFrame.size.width = f[7] / scale;
        appFrame.size.height = f[8] / scale;

        [[UIScreen mainScreen] setBounds:bounds applicationFrame:appFrame scale:scale];
    }
}

- (void) teardownSurface
{
    Real_UIViewController* vc = self.delegate.window.rootViewController;
    if (vc) {
        [vc resetTouches];
    }

    if (_surface != EGL_NO_SURFACE) {
        NSLog(@"Destroying EGL surface...");
        eglMakeCurrent(_display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        eglDestroySurface(_display, _surface);
        _surface = EGL_NO_SURFACE;
    }
}

- (void) teardownGL
{
    [self teardownSurface];

    if (_display != EGL_NO_DISPLAY) {
        NSLog(@"Destroying EGL display...");
        eglMakeCurrent(_display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        if (_context != EGL_NO_CONTEXT) {
            eglDestroyContext(_display, _context);
        }
        if (_surface != EGL_NO_SURFACE) {
            eglDestroySurface(_display, _surface);
        }
        eglTerminate(_display);
    }
    _display = EGL_NO_DISPLAY;
    _context = EGL_NO_CONTEXT;
}

- (void) updateGL:(BOOL)byForceIfNecessary
{
    if (_surface == EGL_NO_SURFACE) {
        // No display yet.
        return;
    }
    if (!self.delegate) {
        // App isn't initialized -- draw a loading screen?
        return;
    }

    Real_UIViewController* vc = self.delegate.window.rootViewController;
    AP_CHECK(vc, return);

    int maxIdleCount = byForceIfNecessary ? 0 : 8;

    ++_idleCount;
    if (_idleCount < vc.idleFrameCount && _idleCount < maxIdleCount) {
//        NSLog(@"Idling (update count %d, max %d)", _idleCount, maxIdleCount);
        return;
    }
    _idleCount = 0;

    if (byForceIfNecessary || !vc.paused) {
        eglMakeCurrent(_display, _surface, _surface, _context);
        [vc draw];
        glFlush();
        eglSwapBuffers(_display, _surface);

        EGLint err = eglGetError();
        if (err != EGL_SUCCESS) {
            // Some errors are transient, bah. We can't try tearing down
            // and rebuilding the surface because we might be in the background.
            // Cleanly restarting the entire game might be good, but it's tricky.
            // Just log the error to help diagnose visual glitches, I guess.
            NSLog(@"*** EGL error: %x", err);
        }

        GLenum err2 = glGetError();
        if (err2 != GL_NO_ERROR) {
            NSLog(@"*** GL error: %x", err2);
        }
    }
}

- (Real_UITouch*) touchForPointerID:(int32_t)pointerID x:(float)x y:(float)y
{
    NSNumber* n = [NSNumber numberWithInt:pointerID];
    Real_UITouch* result = [_touches objectForKey:n];
    if (!result) {
        result = [[Real_UITouch alloc] init];
        [_touches setObject:result forKey:n];
    }
    float scale = [UIScreen mainScreen].scale;
    result.location = CGPointMake(x / scale, y / scale);
    return result;
}

- (void) deletePointerID:(int32_t)pointerID
{
    NSNumber* n = [NSNumber numberWithInt:pointerID];
    [_touches removeObjectForKey:n];
}

- (BOOL) handleInputEvent:(AInputEvent*)event
{
    Real_UIViewController* vc = self.delegate.window.rootViewController;
    if (!vc) {
        NSLog(@"App isn't initialized yet -- ignoring input event");
        return NO;
    }

    if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_KEY
        && AKeyEvent_getKeyCode(event) == AKEYCODE_BACK
        && AKeyEvent_getAction(event) == AKEY_EVENT_ACTION_UP) {
        // FIXME
        return NO; // [self.delegate goBack];
    }

    if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_MOTION) {
        int64_t nanos = AMotionEvent_getEventTime(event);
        double secs = nanos / (1000.0 * 1000.0 * 1000.0);
        Real_UIEvent* e = [[Real_UIEvent alloc] init];
        e.timestamp = secs;

        NSMutableSet* set = [NSMutableSet set];

        int32_t action = AMotionEvent_getAction(event) & AMOTION_EVENT_ACTION_MASK;
        if (action == AMOTION_EVENT_ACTION_MOVE) {
            // Look up all the touch locations.
            int32_t count = AMotionEvent_getPointerCount(event);
            for (int i = 0; i < count; ++i) {
                int32_t pointer = AMotionEvent_getPointerId(event, i);
                float x = AMotionEvent_getX(event, i);
                float y = AMotionEvent_getY(event, i);
                Real_UITouch* touch = [self touchForPointerID:pointer x:x y:y];
                [set addObject:touch];
            }
            [vc touchesMoved:set withEvent:e];
        } else if (action == AMOTION_EVENT_ACTION_CANCEL) {
            // Cancel all the touches.
            [set addObjectsFromArray:[_touches allValues]];
            [vc touchesCancelled:set withEvent:e];
            [_touches removeAllObjects];
        } else {
            // It's an UP or DOWN event, with just one pointer.
            int32_t index = (AMotionEvent_getAction(event) & AMOTION_EVENT_ACTION_POINTER_INDEX_MASK) >> AMOTION_EVENT_ACTION_POINTER_INDEX_SHIFT;
            int32_t pointer = AMotionEvent_getPointerId(event, index);
            float x = AMotionEvent_getX(event, index);
            float y = AMotionEvent_getY(event, index);
            Real_UITouch* touch = [self touchForPointerID:pointer x:x y:y];
            [set addObject:touch];
            switch(action) {
                case AMOTION_EVENT_ACTION_DOWN:
                case AMOTION_EVENT_ACTION_POINTER_DOWN:
                    [self javaVoidMethod:&kHideStatusBar];
                    [vc touchesBegan:set withEvent:e];
                    break;
                case AMOTION_EVENT_ACTION_UP:
                case AMOTION_EVENT_ACTION_POINTER_UP:
                    [vc touchesEnded:set withEvent:e];
                    [self deletePointerID:pointer];
                    break;
                default:
                    NSLog(@"Unexpected motion event! Action ID: %d", action);
                    break;
            }
        }
        return YES;
    }
    return NO;
}

- (void) lowMemory
{
    [[NSNotificationCenter defaultCenter]
        postNotificationName:UIApplicationDidReceiveMemoryWarningNotification
        object:nil];
}

- (void) handleAppCmd:(int32_t)cmd
{
    switch (cmd) {
        case APP_CMD_RESUME:
            _inForeground = YES;
            _autoQuitTime = nil;
            CkResume();
            break;

        case APP_CMD_PAUSE:
        case APP_CMD_STOP:
            _inForeground = NO;
            if (self.isCrappyDevice) {
                _autoQuitTime = [[NSDate date] dateByAddingTimeInterval:30];
            } else {
                _autoQuitTime = [[NSDate date] dateByAddingTimeInterval:300];
            }
            CkSuspend();
            break;

        case APP_CMD_LOW_MEMORY:
            NSLog(@"*** Low memory warning, freeing some non-essential resources ***");
            [self lowMemory];
            break;

        case APP_CMD_SAVE_STATE:
            // The system has asked us to save our current state.  Do so.
            // engine->app->savedState = malloc(sizeof(struct saved_state));
            // *((struct saved_state*)engine->app->savedState) = engine->state;
            // engine->app->savedStateSize = sizeof(struct saved_state);
            break;

        case APP_CMD_INIT_WINDOW:
            // The window is being shown, get it ready.
            if (_android->window) {
                [self maybeInitSurface];
                [self maybeInitApp];
            }
            break;

        case APP_CMD_WINDOW_REDRAW_NEEDED:
            if (_android->window) {
                [self updateGL:YES];
            }
            break;

        case APP_CMD_TERM_WINDOW:
            [self lowMemory];
            [self teardownSurface];
            break;

        case APP_CMD_WINDOW_RESIZED:
        case APP_CMD_CONFIG_CHANGED:
            [self updateScreenSize];
            break;

        case APP_CMD_GAINED_FOCUS:
        case APP_CMD_LOST_FOCUS:
            break;
    }
}

@end

static int32_t handleInputEvent(struct android_app* app, AInputEvent* event) {
    AP_CHECK(g_Main, return 0);
    return [g_Main handleInputEvent:event] ? 1 : 0;
}

static void handleAppCmd(struct android_app* app, int32_t cmd) {
    NSLog(@"handleAppCmd: %d", cmd);
    AP_CHECK(g_Main, return);
    [g_Main handleAppCmd:cmd];
}

void android_main(struct android_app* android) {
    // Make sure glue isn't stripped.
    app_dummy();

    Main* app = [[Main alloc] initWithAndroidApp:android];
    AP_CHECK(app == g_Main, abort());

    android->onAppCmd = handleAppCmd;
    android->onInputEvent = handleInputEvent;

    if (android->savedState != NULL) {
        // We are starting with a previous saved state; restore from it.
    }

    // loop waiting for stuff to do.
    while (1) {
        @autoreleasepool {
            // If not animating, we will block forever waiting for events.
            // If animating, we loop until all events are read, then continue
            // to draw the next frame of animation.

            int timeout;
            if (!g_Main.inForeground) {
                timeout = 10 * 1000;
                [g_Main maybeAutoQuit];
            } else if (g_Main.canDraw && g_Main.idleCount < 4) {
                timeout = 0;
            } else {
                timeout = 30;
            }

            BOOL gotInput = NO;
            while (1) {
                // Read all pending events.
                struct android_poll_source* source;
                int events;
                int ident = ALooper_pollAll(timeout, NULL, &events, (void**)&source);
                if (ident <= 0) {
                    break;
                }

                gotInput = YES;
                timeout = 0; // Get all subsequent events as quickly as possible.

                // Process this event.
                if (source != NULL) {
                    source->process(android, source);
                }

                // Check if we are exiting.
                if (android->destroyRequested != 0) {
                    CkShutdown();
                    [g_Main teardownGL];
                    [g_Main teardownJava];
                    // Despite telling us we're shutting down, the system doesn't kill us, so...
                    exit(EXIT_SUCCESS);
                    return;
                }
            }

            CkUpdate();

            if (g_Main.canDraw) {
                // Run Objective-C timers.
                NSDate* now = [NSDate date];
                NSDate* nextTimer;
                do {
                    nextTimer = [g_RunLoop limitDateForMode:NSDefaultRunLoopMode];
                } while (nextTimer && [now compare:nextTimer] != NSOrderedAscending);

                // Run callbacks.
                [g_RunLoop acceptInputForMode:NSDefaultRunLoopMode beforeDate:nil];

                // Apparently it can take a few frames for e.g. screen rotation
                // to kick in, even after we get notified. What a crock.
                // Let's just poll it every frame.
                [g_Main updateScreenSize];
                [g_Main updateGL:gotInput];
            }
        }
    }
}
