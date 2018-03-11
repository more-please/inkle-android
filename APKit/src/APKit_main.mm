#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
// #import <curl/curl.h>
#import <PAK/PAK.h>

#import <map>
#import <vector>

#import <jni.h>
#import <errno.h>
#import <unistd.h>
#import <sys/statfs.h>
#import <fcntl.h>

#import <EGL/egl.h>
#import <GLES2/gl2.h>

#import <android/log.h>
#import <android/sensor.h>
#import <android/asset_manager.h>
#import <android/asset_manager_jni.h>
#import <android/storage_manager.h>
#import <android_native_app_glue.h>

#import <ck/ck.h>
#import <ck/customfile.h>
#import <ck/mixer.h>

#import <unicode/udata.h>
#import <unicode/uloc.h>

#include <objc/blocks_runtime.h>
#include <objc/hooks.h>

#import "APKit.h"

#import "APKit_main.h"

@interface AsyncResult : NSObject
@property(nonatomic) int handle;
@property(nonatomic,strong) NSString* string;
@property(nonatomic) BOOL boolean;
@end

@implementation AsyncResult
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

#if 0
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
static JavaMethod kParseObjectId = {
    "parseObjectId", "(Lcom/parse/ParseObject;)Ljava/lang/String;", NULL
};
static JavaMethod kParseAddKey = {
    "parseAddKey", "(Lcom/parse/ParseObject;Ljava/lang/String;Ljava/lang/Object;)V", NULL
};
static JavaMethod kParseRemoveKey = {
    "parseRemoveKey", "(Lcom/parse/ParseObject;Ljava/lang/String;)V", NULL
};
static JavaMethod kParseSave = {
    "parseSave", "(ILcom/parse/ParseObject;)V", NULL
};
static JavaMethod kParseSaveEventually = {
    "parseSaveEventually", "(ILcom/parse/ParseObject;)V", NULL
};
static JavaMethod kParseFetch = {
    "parseFetch", "(ILcom/parse/ParseObject;)V", NULL
};
static JavaMethod kParseRefresh = {
    "parseRefresh", "(ILcom/parse/ParseObject;)V", NULL
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
#endif

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
static JavaMethod kShareJourney = {
    "shareJourney", "(Ljava/lang/String;I)V", NULL
};
static JavaMethod kMailTo = {
    "mailTo", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V", NULL
};
static JavaMethod kMaybeGetURL = {
    "maybeGetURL", "()Ljava/lang/String;", NULL
};

// static void parseObjResult(JNIEnv*, jobject, jint, jstring);
// static void parseBoolResult(JNIEnv*, jobject, jint, jboolean);
static void shareJourneyResult(JNIEnv*, jobject, jint, jstring);

static JNINativeMethod kNatives[] = {
//     { "parseObjResult", "(ILjava/lang/String;)V", (void *)&parseObjResult},
//     { "parseBoolResult", "(IZ)V", (void *)&parseBoolResult},
    { "shareJourneyResult", "(ILjava/lang/String;)V", (void *)&shareJourneyResult},
};

static int _NSLog_fd = -1;

static double timeInSeconds() {
    struct timespec t;
    /* int result = */ clock_gettime(CLOCK_MONOTONIC, &t);
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

static void NSLog_flush(NSString* message) {
    if (_NSLog_fd >= 0) {
        NSLog_handler(message);
        fsync(_NSLog_fd);
    }
}

static void CkLog_handler(CkLogType t, const char* msg) {
    NSLog(@"%s", msg);
}

static void logStatfs(NSString* path) {
    if (path) {
        struct statfs s;
        int result = statfs(path.UTF8String, &s);
        if (result == 0) {
            float total = float(s.f_blocks) * float(s.f_bsize) / (1024.0 * 1024.0);
            float avail = float(s.f_bavail) * float(s.f_bsize) / (1024.0 * 1024.0);
            NSLog(@"statfs(%@): total %.1f MB, avail %.1f MB (%.1f%%)", path, total, avail, 100.0 * avail / total);
        } else {
            NSLog(@"*** statfs(%@) returned error: %s", path, strerror(errno));
        }
    }
}

class PakSound : public CkCustomFile
{
    NSString* _name;
    PAK_Item* _item;
    NSData* _data;
    const char* _ptr;
    int _len;
    int _pos;

public:
    PakSound(const char* name) {
        _name = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];

        _item = [PAK_Search item:_name];
        _data = _item.data;
        _ptr = (const char*) _data.bytes;
        _len = (int) _data.length;
        _pos = 0;
    }

    /** Returns true if the file was successfully opened. */
    virtual bool isValid() const {
        return _ptr;
    }

    /** Read from the file.  Returns number of bytes actually read. */
    virtual int read(void* buf, int bytes) {
//         NSLog(@"Reading %d bytes at %d from %@", bytes, _pos, _name);
        if (_pos + bytes > _len) {
            bytes = _len - _pos;
        }
        if (bytes < 0) {
            bytes = 0;
        }
        memcpy(buf, _ptr + _pos, bytes);
        _pos += bytes;
        return bytes;
    }

    /** Returns the size of the file. */
    virtual int getSize() const {
        return _len;
    }

    /** Sets the read position in the file. */
    virtual void setPos(int pos) {
//         NSLog(@"Setting pos to %d in %@", pos, _name);
        if (pos < 0) {
            pos = 0;
        }
        if (pos > _len) {
            pos = _len;
        }
        _pos = pos;
    }

    /** Returns the read position in the file. */
    virtual int getPos() const {
        return _pos;
    }

    static CkCustomFile* customFileFunc(const char* path, void* data) {
        return new PakSound(path);
    }
};

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

    CGRect _oldBounds;

    BOOL _inForeground;
    NSDate* _autoQuitTime;

    NSMutableDictionary* _touches; // Map of ID -> UITouch

    NSMutableDictionary* _blocks; // Map of int -> block

    jobject _gaiDefaultTracker;
    NSArray* _pakNamesCache;
}

- (BOOL) maybeMountAsset:(const char*)name
{
    AAsset* pakAsset = AAssetManager_open(_assetManager, name, AASSET_MODE_BUFFER);
    if (!pakAsset) {
        return NO;
    }
    NSLog(@"Mapping %s...", name);
    if (AAsset_isAllocated(pakAsset)) {
        NSLog(@"*** WARNING, asset is allocated (not mmapped) ***");
        NSLog(@"This is wasting a lot of memory.");
    }

    void* ptr = const_cast<void*>(AAsset_getBuffer(pakAsset));
    if (!ptr) {
        NSLog(@"AAsset_getBuffer failed!");
        return NO;
    }

    off_t size = AAsset_getLength(pakAsset);
    if (!size) {
        NSLog(@"AAsset_getLength failed!");
        return NO;
    }

    NSData* data = [NSData dataWithBytesNoCopy:ptr length:size freeWhenDone:NO];
    if (!data) {
        NSLog(@"dataWithBytesNoCopy failed!");
        return NO;
    }

    PAK* pak = [PAK pakWithData:data];
    if (!pak) {
        NSLog(@"Failed to load game data from %s", name);
        return NO;
    }

    [PAK_Search add:pak];
    return YES;
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
            "inkle",
            NULL
        };
        jint result = _vm->AttachCurrentThread(&_env, &args);
        AP_CHECK(result == JNI_OK, return nil);
        AP_CHECK(_env, return nil);

        // Get InkleActivity and its methods.
        _instance = _env->NewGlobalRef(_android->activity->clazz);
        AP_CHECK(_instance, return nil);

        _class = _env->GetObjectClass(_instance);
        AP_CHECK(_class, return nil);

        _env->RegisterNatives(_class, kNatives, sizeof(kNatives) / sizeof(kNatives[0]));

        self.documentsDir = [self javaStringMethod:&kGetDocumentsDir];
        self.publicDocumentsDir = [self javaStringMethod:&kGetPublicDocumentsDir];
#ifdef DEBUG
        // In debug builds, use /sdcard/Downloads for all files for easier hacking
        self.documentsDir = self.publicDocumentsDir;
#endif
        NSString* defaultsPath = [self.documentsDir stringByAppendingPathComponent:@"NSUserDefaults.plist"];
        [AP_UserDefaults setDefaultsPath:defaultsPath];

        [[AP_UserDefaults standardUserDefaults] startSyncTimer];

        // Send NSLog to a file
        NSString* logfile = [self.documentsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld.log", time(NULL)]];
        _NSLog_fd = open(logfile.UTF8String, O_CREAT | O_WRONLY | O_APPEND, 644);
        if (_NSLog_fd < 0) {
            NSLog(@"*** Error opening log file: %s", strerror(errno));
        } else {
            NSLog(@"Logging to: %@", logfile);
            _NSLog_printf_handler = NSLog_handler;
        }

        NSLog(@"Architecture: %s", STRINGIFY(INKLE_ARCH));

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

        logStatfs(self.documentsDir);
        logStatfs(self.publicDocumentsDir);
        logStatfs(_obbPath);

        // Load the patch first, so it takes priority.
        if ([self maybeMountAsset:"patch.ogg"]) {
            NSLog(@"Loaded game data patch");
        }

        // Load the main game data file.
        if ([self maybeMountAsset:"main.ogg"]) {
            NSLog(@"Loaded game data from asset (Amazon style)");
        } else {
            PAK* pak = [PAK pakWithMemoryMappedFile:_obbPath];
            NSAssert(pak, @"Can't find game data file!");
            [PAK_Search add:pak];
            NSLog(@"Loaded game data from OBB (Google style)");
        }

        // Add ourselves as a backup resource bundle (APK assets)
        [PAK_Search add:self];

        // A cheat: assume all the sounds are in the OBB, so we
        // don't have to bother checking assets (which are very slow).
        _pakNamesCache = [NSArray array];

        // Initialize Cricket Audio
        CkConfig config(_env, _android->activity->clazz);
        config.useJavaAudio = true; // OpenSLES is totally broken.
        // Nice big audio buffers, to prevent any glitches.
        config.audioUpdateMs = 50;
        config.streamBufferMs = 3000;
        config.streamFileUpdateMs = 600;

        // Intercept log output
        config.logFunc = CkLog_handler;

        int success = CkInit(&config);
        if (success) {
            CkSetCustomFileHandler(PakSound::customFileFunc, NULL);
            [AVAudioPlayer setEnabled:YES];
        } else {
            NSLog(@"*** CkInit failed! Will continue without sound.");
        }

        _touches = [NSMutableDictionary dictionary];
        _blocks = [NSMutableDictionary dictionary];
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
        NSLog(@"*** Game is idle in the background. Auto-quitting to save memory.");
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
            // Sorcery! sounds
            "AudioLoops",
            "AudioShuffles",
            "CommonAudioLoops",
            "CommonAudioShuffles",
            // Eighty days
            "AudioSoundScapeSamples",
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
    AP_CHECK(path, return nil);
    AAsset* asset = AAssetManager_open(_assetManager, path.UTF8String, AASSET_MODE_STREAMING);
    if (!asset) {
//         NSLog(@"Failed to open asset: %@", path);
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
        return [[PAK_Item alloc] initWithParent:nil name:path length:data.length data:data];
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
    return _inForeground && _surface != EGL_NO_SURFACE;
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

class PushLocalFrame {
    JNIEnv* _env;
public:
    PushLocalFrame(JNIEnv* env) : _env(env) {
        _env->PushLocalFrame(16);
    }
    ~PushLocalFrame() {
        if (_env->ExceptionOccurred()) {
            _env->ExceptionDescribe();
            _env->ExceptionClear();
        }
        _env->PopLocalFrame(NULL);
    }
};

- (void) javaVoidMethod:(JavaMethod*)m
{
    [self maybeInitJavaMethod:m];
    PushLocalFrame frame(_env);
    _env->CallVoidMethod(_instance, m->method);
}

- (void) javaVoidMethod:(JavaMethod*)m withString:(NSString*)s
{
    [self maybeInitJavaMethod:m];

    PushLocalFrame frame(_env);
    jstring jstr = _env->NewStringUTF(s.UTF8String);
    _env->CallVoidMethod(_instance, m->method, jstr);
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

    PushLocalFrame frame(_env);

    jstring str = (jstring) _env->CallObjectMethod(_instance, m->method);
    NSString* result = nil;
    if (str) {
        const char* c = _env->GetStringUTFChars(str, NULL);
        result = [NSString stringWithCString:c];
        _env->ReleaseStringUTFChars(str, c);
    }
    return result;
}

- (BOOL) javaFloatsMethod:(JavaMethod*)m ptr:(float*)ptr size:(size_t)size
{
    [self maybeInitJavaMethod:m];

    PushLocalFrame frame(_env);

    jfloatArray arr = (jfloatArray) _env->CallObjectMethod(_instance, m->method);
    AP_CHECK(arr, return NO);
    AP_CHECK(_env->GetArrayLength(arr) == size, return NO);

    jfloat* f = _env->GetFloatArrayElements(arr, NULL);
    for (int i = 0; i < size; ++i) {
        ptr[i] = f[i];
    }
    _env->ReleaseFloatArrayElements(arr, f, 0);

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

    PushLocalFrame frame(_env);

    jstring str = _env->NewStringUTF(name.UTF8String);
    jclass result = (jclass) _env->CallObjectMethod(_instance, kFindClass.method, str);
    result = (jclass) _env->NewGlobalRef(result);

    return result;
}

- (void) stayAwake
{
    [self javaVoidMethod:&kHideStatusBar];
}

- (NSString*) versionName
{
    return [self javaStringMethod:&kVersionName];
}

- (int) versionCode
{
    return [self javaIntMethod:&kVersionCode];
}

- (int) pushBlock:(id)block
{
    static int handle = 0;
    ++handle;
    if (block) {
        [_blocks setObject:block forKey:@(handle)];
    }
    return handle;
}

- (id) popBlock:(int)handle
{
    id result = [_blocks objectForKey:@(handle)];
    if (result) {
        [_blocks removeObjectForKey:@(handle)];
    }
    return result;
}

#if 0

static void parseObjResult(JNIEnv* env, jobject obj, jint i, jstring s) {
    AsyncResult* result = [[AsyncResult alloc] init];
    result.handle = i;
    if (s) {
        const char* c = env->GetStringUTFChars(s, NULL);
        result.string = [NSString stringWithCString:c encoding:NSUTF8StringEncoding];
        env->ReleaseStringUTFChars(s, c);
    }

    // NSLog(@"Posting parseCallResult handle:%d string:%@", result.handle, result.string);
    [g_Main performSelectorOnMainThread:@selector(parseObjResult:)
        withObject:result
        waitUntilDone:NO];
}

- (void) parseObjResult:(AsyncResult*)result
{
    // NSLog(@"parseCallResult handle:%d string:%@", result.handle, result.string);
    PFIdResultBlock block = [self popBlock:result.handle];
    if (block) {
        NSError* error = nil;
        id json = [self jsonDecode:result error:&error];
        block(json, error);
    }
}

static void parseBoolResult(JNIEnv* env, jobject obj, jint i, jboolean b) {
    AsyncResult* result = [[AsyncResult alloc] init];
    result.handle = i;
    result.boolean = b;

    // NSLog(@"Posting parseSaveResult handle:%d result:%d", result.handle, result.boolean);
    [g_Main performSelectorOnMainThread:@selector(parseBoolResult:)
        withObject:result
        waitUntilDone:NO];
}

- (void) parseBoolResult:(AsyncResult*)result
{
    // NSLog(@"parseSaveResult handle:%d value:%d", result.handle, result.boolean);
    PFBooleanResultBlock block = [self popBlock:result.handle];
    if (block) {
        NSError* error = result.boolean ? nil : [NSError errorWithDomain:@"Parse" code:-1 userInfo:nil];
        block(result.boolean, error);
    }
}

- (void) parseInitWithApplicationId:(NSString*)applicationId host:(NSString*)host
{
    [self maybeInitJavaMethod:&kParseInit];

    PushLocalFrame frame(_env);
    jstring jApplicationId = _env->NewStringUTF(applicationId.UTF8String);
    jstring jHost = _env->NewStringUTF(host.UTF8String);

    _env->CallVoidMethod(_instance, kParseInit.method, jApplicationId, jHost);
}

- (void) parseCallFunction:(NSString*)function parameters:(NSDictionary*)params block:(PFIdResultBlock)block
{
    int handle = [self pushBlock:block];

    [self maybeInitJavaMethod:&kParseCallFunction];

    PushLocalFrame frame(_env);
    jstring jFunction = _env->NewStringUTF(function.UTF8String);
    jobject jParams = [self jsonEncode:params];

    _env->CallVoidMethod(_instance, kParseCallFunction.method, handle, jFunction, jParams);
}

- (void) parseObject:(jobject)obj fetchWithBlock:(PFObjectResultBlock)block
{
    int handle = [self pushBlock:block];

    [self maybeInitJavaMethod:&kParseFetch];
    _env->CallVoidMethod(_instance, kParseFetch.method, handle, obj);
}

- (void) parseObject:(jobject)obj refreshWithBlock:(PFObjectResultBlock)block
{
    int handle = [self pushBlock:block];

    [self maybeInitJavaMethod:&kParseRefresh];
    _env->CallVoidMethod(_instance, kParseRefresh.method, handle, obj);
}

- (void) parseObject:(jobject)obj saveWithBlock:(PFBooleanResultBlock)block
{
    int handle = [self pushBlock:block];

    [self maybeInitJavaMethod:&kParseSave];
    _env->CallVoidMethod(_instance, kParseSave.method, handle, obj);
}

- (void) parseObject:(jobject)obj saveEventuallyWithBlock:(PFBooleanResultBlock)block
{
    int handle = [self pushBlock:block];

    [self maybeInitJavaMethod:&kParseSaveEventually];
    _env->CallVoidMethod(_instance, kParseSaveEventually.method, handle, obj);
}

- (jobject) parseNewObject:(NSString*)className
{
    [self maybeInitJavaMethod:&kParseNewObject];

    PushLocalFrame frame(_env);
    jstring jName = _env->NewStringUTF(className.UTF8String);

    jobject result = _env->CallObjectMethod(_instance, kParseNewObject.method, jName);
    result = _env->NewGlobalRef(result);

    return result;
}

- (jobject) parseNewObject:(NSString*)className objectId:(NSString*)objectId
{
    [self maybeInitJavaMethod:&kParseNewObjectId];

    PushLocalFrame frame(_env);
    jstring jName = _env->NewStringUTF(className.UTF8String);
    jstring jId = _env->NewStringUTF(objectId.UTF8String);

    jobject result = _env->CallObjectMethod(_instance, kParseNewObjectId.method, jName, jId);
    result = _env->NewGlobalRef(result);

    return result;
}

- (NSString*) parseObjectId:(jobject)obj
{
    [self maybeInitJavaMethod:&kParseObjectId];

    PushLocalFrame frame(_env);

    jstring str = (jstring) _env->CallObjectMethod(_instance, kParseObjectId.method, obj);
    NSString* result = nil;
    if (str) {
        const char* c = _env->GetStringUTFChars(str, NULL);
        result = [NSString stringWithCString:c];
        _env->ReleaseStringUTFChars(str, c);
    }
    return result;
}

- (void) parseObject:(jobject)obj addKey:(NSString*)key value:(id)value
{
    [self maybeInitJavaMethod:&kParseAddKey];

    PushLocalFrame frame(_env);
    jstring jKey = _env->NewStringUTF(key.UTF8String);
    jobject jValue = [self jsonEncode:value];

    _env->CallVoidMethod(_instance, kParseAddKey.method, obj, jKey, jValue);
}

- (void) parseObject:(jobject)obj removeKey:(NSString*)key
{
    [self maybeInitJavaMethod:&kParseRemoveKey];

    PushLocalFrame frame(_env);
    jstring jKey = _env->NewStringUTF(key.UTF8String);

    _env->CallVoidMethod(_instance, kParseRemoveKey.method, obj, jKey);
}

- (jobject) parseNewQuery:(NSString*)className
{
    [self maybeInitJavaMethod:&kParseNewQuery];

    PushLocalFrame frame(_env);
    jstring jName = _env->NewStringUTF(className.UTF8String);

    jobject result = _env->CallObjectMethod(_instance, kParseNewQuery.method, jName);
    result = _env->NewGlobalRef(result);
    return result;
}

- (void) parseQuery:(jobject)obj whereKey:(NSString*)key equalTo:(id)value
{
    [self maybeInitJavaMethod:&kParseWhereEqualTo];

    PushLocalFrame frame(_env);
    jstring jKey = _env->NewStringUTF(key.UTF8String);
    jobject jValue = [self jsonEncode:value];

    _env->CallVoidMethod(_instance, kParseWhereEqualTo.method, obj, jKey, jValue);
}

- (void) parseQuery:(jobject)obj findWithBlock:(PFArrayResultBlock)block
{
    int handle = [self pushBlock:block];
    [self maybeInitJavaMethod:&kParseFind];
    _env->CallVoidMethod(_instance, kParseFind.method, handle, obj);
}

- (void) parseEnableAutomaticUser
{
    [self javaVoidMethod:&kParseEnableAutomaticUser];
}

- (jobject) parseCurrentUser
{
    [self maybeInitJavaMethod:&kParseCurrentUser];

    PushLocalFrame frame(_env);

    jobject result = _env->CallObjectMethod(_instance, kParseCurrentUser.method);
    result = _env->NewGlobalRef(result);
    return result;
}

#endif

- (jobject) jsonEncode:(id)value
{
    if (!value) {
        return NULL;
    }
//     if ([value isKindOfClass:[PFObject class]]) {
//         // Send PFObjects without any encoding
//         PFObject* pf = (PFObject*) value;
//         return (jobject)pf.jobj;
//     }

    // Otherwise, encode as JSON.
    NSError* error = nil;
    NSData* valueData = [NSJSONSerialization dataWithJSONObject:value options:0 error:&error];
    if (error) {
        NSLog(@"JSON writer error: %@", error);
        return NULL;
    }
    const char zero = 0;
    NSMutableData* nullTerminated = [NSMutableData dataWithData:valueData];
    [nullTerminated appendBytes:&zero length:1];
    return _env->NewStringUTF((const char*)nullTerminated.bytes);
}

- (id) jsonDecode:(AsyncResult*)result error:(NSError**)error
{
    if (result.string) {
//        NSLog(@"Decoding JSON: %@", result.string);
        NSData* data = [result.string dataUsingEncoding:NSUTF8StringEncoding];
        *error = nil;
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
//        NSLog(@"Result: %@", json);
        return json;
    } else {
        *error = [NSError errorWithDomain:@"Parse" code:-1 userInfo:nil];
        return nil;
    }
}

- (AAssetManager*) getAssets
{
    [self maybeInitJavaMethod:&kGetAssets];

    PushLocalFrame frame(_env);

    jobject obj = _env->CallObjectMethod(_instance, kGetAssets.method);
    obj = _env->NewGlobalRef(obj);
    AAssetManager* result = AAssetManager_fromJava(_env, obj);
    if (!result) {
        NSLog(@"Failed to open AssetManager!");
        abort();
    }

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

    PushLocalFrame frame(_env);
    jstring s1 = text ? _env->NewStringUTF(text.UTF8String) : NULL;
    jstring s2 = url ? _env->NewStringUTF(url.UTF8String) : NULL;
    jstring s3 = image ? _env->NewStringUTF(image.UTF8String) : NULL;
    _env->CallVoidMethod(_instance, kTweet.method, s1, s2, s3);
}

- (void) shareJourneyWithName:(NSString*)existingName block:(NameResultBlock)block
{
    [self maybeInitJavaMethod:&kShareJourney];

    int handle = [self pushBlock:block];

    PushLocalFrame frame(_env);
    jstring s = existingName ? _env->NewStringUTF(existingName.UTF8String) : NULL;
    _env->CallVoidMethod(_instance, kShareJourney.method, s, handle);
}

static void shareJourneyResult(JNIEnv* env, jobject obj, jint i, jstring s) {
    AsyncResult* result = [[AsyncResult alloc] init];
    result.handle = i;
    if (s) {
        const char* c = env->GetStringUTFChars(s, NULL);
        result.string = [NSString stringWithCString:c encoding:NSUTF8StringEncoding];
        env->ReleaseStringUTFChars(s, c);
    }

    NSLog(@"Posting shareJourneyResult handle:%d result:%@", result.handle, result.string);
    [g_Main performSelectorOnMainThread:@selector(shareJourneyResult:)
        withObject:result
        waitUntilDone:NO];
}

- (void) shareJourneyResult:(AsyncResult*)result
{
    NSLog(@"shareJourneyResult handle:%d value:%@", result.handle, result.string);
    NameResultBlock block = [self popBlock:result.handle];
    if (block) {
        block(result.string);
    }
}

- (void) mailTo:(NSString*)to message:(NSString*)message attachment:(NSString*)path
{
    [self maybeInitJavaMethod:&kMailTo];

    PushLocalFrame frame(_env);
    jstring s1 = to ? _env->NewStringUTF(to.UTF8String) : NULL;
    jstring s2 = message ? _env->NewStringUTF(message.UTF8String) : NULL;
    jstring s3 = path ? _env->NewStringUTF(path.UTF8String) : NULL;
    _env->CallVoidMethod(_instance, kMailTo.method, s1, s2, s3);
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

    [self maybeInitSurface];

    if (_surface == EGL_NO_SURFACE) {
        // No surface, can't draw
        return;
    }

    if (!eglMakeCurrent(_display, _surface, _surface, _context)) {
        NSLog(@"*** eglMakeCurrent failed!");
        [self teardownSurface];
        return;
    }

    NSLog(@"Let's get started!");
    id<AP_ApplicationDelegate> delegate = AP_GetDelegate();
    self.delegate = delegate;

    // Splash screen

    [self updateScreenSize];

    AP_Window* window = [[AP_Window alloc] init];
    delegate.window = [[Real_UIWindow alloc] init];
    delegate.window.rootViewController = window; // Err, yes, well

#ifdef EIGHTY_DAYS
    AP_Image* logo = [AP_Image imageNamed:@"80-days-logo"];
    logo = [logo imageWithWidth:[AP_Window widthForIPhone:150 iPad:250]];
#else
    AP_Image* logo = [AP_Image imageNamed:@"sorcery-title"];
    logo = [logo imageScaledBy:0.75];
#endif

    AP_ImageView* view = [[AP_ImageView alloc] initWithImage:logo];
    view.frame = [[UIScreen mainScreen] bounds];
    view.contentMode = UIViewContentModeCenter;
    view.autoresizingMask = UIViewAutoresizing(-1);

    AP_ViewController* controller = [[AP_ViewController alloc] init];
    controller.view = view;
    window.rootViewController = controller;

    [self updateGL:YES];

    // Lollipop seems to reject the first frame, because the window is the wrong size...?
    // Just sending another frame seems to do the trick.
    [self updateGL:YES];

    // Without this, the splash screen gets leaked...?
    window.rootViewController = nil;

    NSLog(@"Initializing ICU...");
    NSData* icuDat = [NSBundle dataForResource:@"icudt51l.dat" ofType:nil];
    UErrorCode icuErr = U_ZERO_ERROR;
    udata_setCommonData(icuDat.bytes, &icuErr);
    NSAssert(U_SUCCESS(icuErr), @"ICU error: %d", icuErr);

    // Hard-code the local to en_GB, as some others use characters we don't support.
    NSString* locale = @"en_GB"; // [self javaStringMethod:&kGetLocale];
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
    NSLog(@"Score: %.0f", [self scoreConfig:c]);
}

- (double) scoreConfig:(EGLConfig)c
{
    EGLint red, green, blue, alpha, stencil, depth, samples;

    eglGetConfigAttrib(_display, c, EGL_RED_SIZE, &red);
    eglGetConfigAttrib(_display, c, EGL_GREEN_SIZE, &green);
    eglGetConfigAttrib(_display, c, EGL_BLUE_SIZE, &blue);
    eglGetConfigAttrib(_display, c, EGL_ALPHA_SIZE, &alpha);
    eglGetConfigAttrib(_display, c, EGL_STENCIL_SIZE, &stencil);
    eglGetConfigAttrib(_display, c, EGL_DEPTH_SIZE, &depth);
    eglGetConfigAttrib(_display, c, EGL_SAMPLES, &samples);

    const double BAD = 0;

    // We'll multiply the score each round, so the most important checks come first.
    double score = 1;

    // Preferably no alpha, because it barely works on the Kindle Fire.
    score = 100 * score - alpha;

    // More RGB is better
    score = 100 * score + red + green + blue;

#ifndef EIGHTY_DAYS
    // For Sorcery, MSAA isn't worth the performance hit -- less is better.
    score = 100 * score - samples;
#else
    // For Eighty Days, MSAA is nice (but more than 4x is overkill)
    if (samples > 4) {
        return BAD;
    }
    score = 100 * score + samples;
#endif

    // Must have at least 16-bit depth (but less is better)
    if (depth < 16) {
        return BAD;
    }
    score = 100 * score - depth;

    // Must have at least 4-bit stencil (but less is better)
    if (stencil < 4) {
        return BAD;
    }
    score = 100 * score - stencil;

    return score;
}

const EGLint basicAttribs[] = {
        EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
        EGL_NONE
};

- (void) maybeInitGL
{
    if (_display == EGL_NO_DISPLAY) {
        NSLog(@"Initializing EGL display...");

        _display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
        eglInitialize(_display, 0, 0);

        EGLint numConfigs;
        eglChooseConfig(_display, basicAttribs, NULL, 0, &numConfigs);
        NSLog(@"There are %d ES2-capable screen configs", numConfigs);
        if (numConfigs <= 0) {
            abort();
        }

        std::vector<EGLConfig> configs(numConfigs);
        eglChooseConfig(_display, basicAttribs, &configs[0], numConfigs, &numConfigs);

#ifdef DEBUG
        NSLog(@"----------------");
        for (int i = 0; i < numConfigs; ++i) {
            [self dumpConfig:configs[i]];
            NSLog(@"----------------");
        }
#endif

        int bestConfig = 0;
        double bestScore = [self scoreConfig:configs[0]];
        for (int i = 1; i < numConfigs; ++i) {
            double score = [self scoreConfig:configs[i]];
            if (score > bestScore) {
                bestScore = score;
                bestConfig = i;
            }
        }

        _config = configs[bestConfig];
        NSLog(@"Selected config:");
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
    [self maybeInitGL];

    if (_surface == EGL_NO_SURFACE && _android->window) {
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

        NSLog(@"GL_VENDOR: %s", glGetString(GL_VENDOR));
        NSLog(@"GL_RENDERER: %s", glGetString(GL_RENDERER));
    }
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

        int w = bounds.size.width * scale;
        int h = bounds.size.height * scale;
        if (w * h < 1280 * 720 && !self.isCrappyDevice) {
            NSLog(@"Screen size is %d x %d, skipping hi-res textures", w, h);
            self.isCrappyDevice = YES;
        }

        if (!CGRectEqualToRect(bounds, _oldBounds) && !CGRectEqualToRect(_oldBounds, CGRectZero)) {
            NSLog(@"*** Screen size changed, tearing down GL surface");
            [self teardownSurface];
            [self maybeInitSurface];
        }
        _oldBounds = bounds;
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

    // Not much we can do with errors here, but let's at least log it and clear it.
    EGLint err = eglGetError();
    if (err != EGL_SUCCESS) {
        NSLog(@"*** EGL error: %x", err);
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
    if (_display == EGL_NO_DISPLAY) {
        // No display yet.
        return;
    }

    if (!self.delegate) {
        // App isn't initialized -- draw a loading screen?
        return;
    }

    [self maybeInitSurface];

    if (_surface == EGL_NO_SURFACE) {
        // No surface, can't draw
        return;
    }

    if (!eglMakeCurrent(_display, _surface, _surface, _context)) {
        NSLog(@"*** eglMakeCurrent failed!");
        [self teardownSurface];
        return;
    }

    Real_UIViewController* vc = self.delegate.window.rootViewController;
    AP_CHECK(vc, return);

    if ([vc update]) {
        _idleCount = 0;
    } else {
        ++_idleCount;
    }
    
    if (byForceIfNecessary || _idleCount < 2) {
        [vc draw];
        _GL(Flush);
        eglSwapBuffers(_display, _surface);

        GLenum err = glGetError();
        if (err != GL_NO_ERROR) {
            NSLog(@"*** GL error: %x", err);
        }

        EGLint err2 = eglGetError();
        if (err2 != EGL_SUCCESS) {
            NSLog(@"*** EGL error: %x", err2);
            // Some devices with bad GL drivers seem to raise EGL_BAD_SURFACE
            // more or less randomly. On the Galaxy Tab 3 10.1 the whole device
            // can eventually lock up. Try tearing down and lazily recreating the
            // surface to see if that helps.
            [self teardownSurface];
        }
    }
}

- (void) maybeDisplayURL
{
    if (!self.delegate) {
        // App isn't initialized yet
    }

    NSString* urlStr = [self javaStringMethod:&kMaybeGetURL];
    if (urlStr) {
        NSURL* url = [NSURL URLWithString:urlStr];
        if (url) {
            NSLog(@"Opening URL: %@", url);
            [self.delegate application:self openURL:url sourceApplication:nil annotation:nil];
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
        return [self.delegate handleAndroidBackButton];
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
            [self teardownSurface];
            break;

        case APP_CMD_INIT_WINDOW:
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

    static std::map<int, const char*> s_cmds;
    if (s_cmds.empty()) {
#define ADD_CMD(c) s_cmds[c] = #c
        ADD_CMD(APP_CMD_INPUT_CHANGED);
        ADD_CMD(APP_CMD_INIT_WINDOW);
        ADD_CMD(APP_CMD_TERM_WINDOW);
        ADD_CMD(APP_CMD_WINDOW_RESIZED);
        ADD_CMD(APP_CMD_WINDOW_REDRAW_NEEDED);
        ADD_CMD(APP_CMD_CONTENT_RECT_CHANGED);
        ADD_CMD(APP_CMD_GAINED_FOCUS);
        ADD_CMD(APP_CMD_LOST_FOCUS);
        ADD_CMD(APP_CMD_CONFIG_CHANGED);
        ADD_CMD(APP_CMD_LOW_MEMORY);
        ADD_CMD(APP_CMD_START);
        ADD_CMD(APP_CMD_RESUME);
        ADD_CMD(APP_CMD_SAVE_STATE);
        ADD_CMD(APP_CMD_PAUSE);
        ADD_CMD(APP_CMD_STOP);
        ADD_CMD(APP_CMD_DESTROY);
#undef ADD_CMD
    }
    const char* name = s_cmds[cmd];
    if (!name) {
        name = "UNKNOWN";
    }
    NSLog(@"handleAppCmd: %d (%s)", cmd, name);

    AP_CHECK(g_Main, return);
    [g_Main handleAppCmd:cmd];
}

extern "C" {
    struct objc_class _NSConcreteStackBlock;
    struct objc_class _NSConcreteGlobalBlock;
}

void android_main(struct android_app* android) {

    objc_set_NSConcreteGlobalBlock((__bridge Class) &_NSConcreteGlobalBlock);
    objc_set_NSConcreteStackBlock((__bridge Class) &_NSConcreteStackBlock);

//     CURLcode curlErr = curl_global_init(CURL_GLOBAL_DEFAULT);
//     if (curlErr) {
//         NSLog(@"*** curl_global_init() failed: %s", curl_easy_strerror(curlErr));
//     }

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
            } else if (g_Main.canDraw && g_Main.idleCount < 2) {
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
                    // Despite telling us we're shutting down, the system doesn't kill us, so...
                    CkShutdown();
                    [g_Main teardownGL];
                    [g_Main teardownJava];
                    // Call _exit() rather than exit() to avoid running C++ destructors.
                    // I've been seeing some audio-related shutdown crashes.
                    NSLog_flush(@"_exit(EXIT_SUCCESS)");
                    _exit(EXIT_SUCCESS);
                    return;
                }
            }

            CkUpdate();

            [g_Main maybeInitSurface];

            if (g_Main.canDraw) {
                [g_Main maybeInitApp];

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

                // Check whether we need to display a URL.
                [g_Main maybeDisplayURL];
            }
        }
    }
}
