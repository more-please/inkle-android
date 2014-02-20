#import <Foundation/Foundation.h>
#import <APKit/APKit.h>

#import <jni.h>
#import <errno.h>

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

#import "SorceryAppDelegate.h"
#import "ExpiredAppDelegate.h"


@interface Main : AP_Application
@property(nonatomic,readonly) BOOL active;
@end

static Main* g_Main;

typedef struct JavaMethod {
    const char* name;
    const char* sig;
    jmethodID method;
} JavaMethod;

static JavaMethod kGetDocumentsDir = {
    "getDocumentsDir", "()Ljava/lang/String;", NULL
};
static JavaMethod kGetExpansionFilePath = {
    "getExpansionFilePath", "()Ljava/lang/String;", NULL
};
static JavaMethod kGetMountedObbPath = {
    "getMountedObbPath", "()Ljava/lang/String;", NULL
};
static JavaMethod kGetScreenInfo = {
    "getScreenInfo", "()[F", NULL
};
static JavaMethod kPleaseFinish = {
    "pleaseFinish", "()V", NULL
};
static JavaMethod kGetAssets = {
    "getAssets", "()Landroid/content/res/AssetManager;", NULL
};

static volatile BOOL g_NeedToCheckObb;

static void obbCallback(const char* filename, const int32_t state, void* data) {
    g_NeedToCheckObb = YES;
}

const char* OBB_KEY = "first-beta-build-woohoo";

@implementation Main {
    struct android_app* _android;

    AStorageManager* _storageManager;
    AAssetManager* _assetManager;
    NSString* _obbPath;
    NSString* _mountPath;

    JavaVM* _vm;
    JNIEnv* _env;
    jclass _class;
    jobject _instance;

    EGLDisplay _display;
    EGLConfig _config;
    EGLContext _context;
    EGLSurface _surface; // This can change across suspend/resume

    BOOL _inForeground;

    NSMutableDictionary* _touches; // Map of ID -> UITouch
}

- (id) initWithAndroidApp:(struct android_app*)android
{
    self = [super init];
    if (self) {
        AP_CHECK(!g_Main, return nil);
        g_Main = self;

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
        config.enableOggVorbis = false;
        int success = CkInit(&config);
        AP_CHECK(success, return nil);

        // Get SorceryActivity and its methods.
        _instance = _env->NewGlobalRef(_android->activity->clazz);
        AP_CHECK(_instance, return nil);

        _class = _env->GetObjectClass(_instance);
        AP_CHECK(_class, return nil);

        self.documentsDir = [self javaStringMethod:&kGetDocumentsDir];
        [NSUserDefaults setDocumentsDir:self.documentsDir];
        NSLog(@"documentsDir: %@", self.documentsDir);

        _touches = [NSMutableDictionary dictionary];

        // Initialize non-OBB assets.

        _assetManager = [self getAssets];

        // Start mounting the OBB.

        _storageManager = AStorageManager_new();
        AP_CHECK(_storageManager, return nil);

        _obbPath = [self javaStringMethod:&kGetExpansionFilePath];
        AP_CHECK(_obbPath, return nil);

        g_NeedToCheckObb = NO;
        AStorageManager_mountObb(
            _storageManager,
            _obbPath.cString,
            OBB_KEY,
            obbCallback,
            NULL);
    }
    return self;
}

- (void) dealloc
{
    [self teardownGL];
    [self teardownJava];
    g_Main = nil;
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
        _env = NULL;
    }
}

- (NSData*) getResource:(NSString*)path
{
    AAsset* asset = AAssetManager_open(_assetManager, path.cString, AASSET_MODE_STREAMING);
    if (!asset) {
        NSLog(@"Failed to open asset: %@", path);
        return nil;
    }

    off_t size = AAsset_getLength(asset);
    NSMutableData* result = [NSMutableData dataWithLength:size];
    char* ptr = (char*) result.bytes;
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
        result = nil;
    }

    AAsset_close(asset);
    return result;
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
        NSLog(@"Initializing JNI method %s...", m->name);
        m->method = _env->GetMethodID(_class, m->name, m->sig);
        NSAssert(m->method, @"JNI method lookup failed!");
        NSLog(@"Initializing JNI method %s... Done.", m->name);
    }
}

- (void) javaVoidMethod:(JavaMethod*)m
{
    [self maybeInitJavaMethod:m];
    _env->CallVoidMethod(_instance, m->method);
}

- (NSString*) javaStringMethod:(JavaMethod*)m
{
    [self maybeInitJavaMethod:m];

    _env->PushLocalFrame(1);

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

    _env->PushLocalFrame(1);

    jfloatArray arr = (jfloatArray) _env->CallObjectMethod(_instance, m->method);
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

- (AAssetManager*) getAssets
{
    [self maybeInitJavaMethod:&kGetAssets];

    _env->PushLocalFrame(1);

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

#define BETA_DAYS 7

- (NSDate*) expiryDate
{
    NSDate* buildDate = [NSDate dateWithTimeIntervalSince1970:SORCERY_BUILD_TIMESTAMP];
    NSDate* expiryDate = [buildDate dateByAddingTimeInterval:(BETA_DAYS * 24 * 60 * 60)];
    return expiryDate;
}

- (BOOL) isExpired:(NSDate*)date
{
    NSDate* expiry = [self expiryDate];
    NSLog(@"Checking expiry date: %@ against: %@", expiry, date);
    return ([expiry compare:date] == NSOrderedAscending);
}

- (void) maybeInitApp
{
    if (_display == EGL_NO_DISPLAY) {
        // No display yet.
        return;
    }
    if (!_mountPath) {
        // No expansion file yet.
        return;
    }
    if (self.delegate) {
        // Already initialized
        return;
    }

    [AP_Bundle mainBundle].root = _mountPath;

    NSString* pakPath = [_mountPath stringByAppendingPathComponent:@"sorcery1_android.pak"];
    AP_PakReader* pak = [AP_PakReader readerWithMemoryMappedFile:pakPath];
    [AP_Bundle addPak:pak];

    // Check that both the current time and the timestamp
    // of the .obb file are before the beta expiry date.
    NSError* err;
    NSDictionary* attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:_obbPath error:&err];
    if (!attrs) {
        NSLog(@"Error checking OBB file attributes: %@", err);
        abort();
    }
    NSDate* now = [NSDate date];
    NSDate* obbDate = [attrs valueForKey:NSFileCreationDate];
    if ([self isExpired:now] || [self isExpired:obbDate]) {
        NSLog(@"Expired!!");
        self.delegate = [[ExpiredAppDelegate alloc] init];
    } else {
        NSLog(@"Let's get started!");
        SorceryAppDelegate* sorcery = [[SorceryAppDelegate alloc] init];
        self.delegate = sorcery;
    }

    NSDictionary* options = [NSDictionary dictionary];
    [self.delegate application:self didFinishLaunchingWithOptions:options];
}

- (void) handleObbCallback
{
    if (AStorageManager_isObbMounted(_storageManager, [_obbPath cString])) {
        AP_CHECK(!_mountPath, abort());
        _mountPath = [self javaStringMethod:&kGetMountedObbPath];
        NSLog(@"OBB mounted at path: %@", _mountPath);
        [self maybeInitApp];
    } else {
        NSLog(@"OBB failed to mount!");
        abort();
    }
}

- (void) maybeInitGL
{
    if (_display == EGL_NO_DISPLAY) {
        NSLog(@"Initializing EGL display...");

        _display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
        eglInitialize(_display, 0, 0);

        // Here specify the attributes of the desired configuration.
        // Below, we select an EGLConfig with at least 8 bits per color
        // component compatible with on-screen windows
        const EGLint attribs[] = {
                EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
                EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
                EGL_BLUE_SIZE, 8,
                EGL_GREEN_SIZE, 8,
                EGL_RED_SIZE, 8,
                EGL_NONE
        };
        EGLint numConfigs;

        // Here, the application chooses the configuration it desires. In this
        // sample, we have a very simplified selection process, where we pick
        // the first EGLConfig that matches our criteria
        eglChooseConfig(_display, attribs, &_config, 1, &numConfigs);

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
    UIViewController* vc = self.delegate.window.rootViewController;
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
    if (!_mountPath) {
        // No expansion file yet.
        return;
    }
    if (!self.delegate) {
        // App isn't initialized -- draw a loading screen?
        return;
    }

    UIViewController* vc = self.delegate.window.rootViewController;
    AP_CHECK(vc, return);

    if (byForceIfNecessary || !vc.paused) {
        eglMakeCurrent(_display, _surface, _surface, _context);
        [vc draw];
        eglSwapBuffers(_display, _surface);

        EGLint err = eglGetError();
        if (err != EGL_SUCCESS) {
            // Some errors are transient, bah. We can't try tearing down
            // and rebuilding the surface because we might be in the background.
            // Cleanly restarting the entire game might be good, but it's tricky.
            // Just log the error to help diagnose visual glitches, I guess.
            NSLog(@"*** EGL error: %x", err);
        }
    }
}

- (UITouch*) touchForPointerID:(int32_t)pointerID x:(float)x y:(float)y
{
    NSNumber* n = [NSNumber numberWithInt:pointerID];
    UITouch* result = [_touches objectForKey:n];
    if (!result) {
        result = [[UITouch alloc] init];
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
    UIViewController* vc = self.delegate.window.rootViewController;
    if (!vc) {
        NSLog(@"App isn't initialized yet -- ignoring input event");
        return NO;
    }

    if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_KEY
        && AKeyEvent_getKeyCode(event) == AKEYCODE_BACK
        && AKeyEvent_getAction(event) == AKEY_EVENT_ACTION_UP) {
        return [self.delegate goBack];
    }

    if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_MOTION) {
        NSMutableSet* set = [NSMutableSet set];

        int32_t action = AMotionEvent_getAction(event) & AMOTION_EVENT_ACTION_MASK;
        if (action == AMOTION_EVENT_ACTION_MOVE) {
            // Look up all the touch locations.
            int32_t count = AMotionEvent_getPointerCount(event);
            for (int i = 0; i < count; ++i) {
                int32_t pointer = AMotionEvent_getPointerId(event, i);
                float x = AMotionEvent_getX(event, i);
                float y = AMotionEvent_getY(event, i);
                UITouch* touch = [self touchForPointerID:pointer x:x y:y];
                [set addObject:touch];
            }
            [vc touchesMoved:set withEvent:nil];
        } else if (action == AMOTION_EVENT_ACTION_CANCEL) {
            // Cancel all the touches.
            [set addObjectsFromArray:[_touches allValues]];
            [vc touchesCancelled:set withEvent:nil];
            [_touches removeAllObjects];
        } else {
            // It's an UP or DOWN event, with just one pointer.
            int32_t index = (AMotionEvent_getAction(event) & AMOTION_EVENT_ACTION_POINTER_INDEX_MASK) >> AMOTION_EVENT_ACTION_POINTER_INDEX_SHIFT;
            int32_t pointer = AMotionEvent_getPointerId(event, index);
            float x = AMotionEvent_getX(event, index);
            float y = AMotionEvent_getY(event, index);
            UITouch* touch = [self touchForPointerID:pointer x:x y:y];
            [set addObject:touch];
            switch(action) {
                case AMOTION_EVENT_ACTION_DOWN:
                case AMOTION_EVENT_ACTION_POINTER_DOWN:
                    [vc touchesBegan:set withEvent:nil];
                    break;
                case AMOTION_EVENT_ACTION_UP:
                case AMOTION_EVENT_ACTION_POINTER_UP:
                    [vc touchesEnded:set withEvent:nil];
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

- (void) handleAppCmd:(int32_t)cmd
{
    switch (cmd) {
        case APP_CMD_RESUME:
            _inForeground = YES;
            CkResume();
            break;

        case APP_CMD_PAUSE:
        case APP_CMD_STOP:
            _inForeground = NO;
            CkSuspend();
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

            NSDate* now = [NSDate date];
            // Run Objective-C timers.
            // TODO: maybe factor limitDate into our polling timeout.
            NSDate* nextTimer;
            do {
                nextTimer = [[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];
            } while (nextTimer && [now compare:nextTimer] != NSOrderedAscending);

            while (1) {
                // Read all pending events.
                struct android_poll_source* source;
                int timeout = g_Main.inForeground ? 0 : -1;
                int events;
                int ident = ALooper_pollAll(timeout, NULL, &events, (void**)&source);
                if (ident <= 0) {
                    break;
                }

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

            if (g_NeedToCheckObb) {
                g_NeedToCheckObb = NO;
                [g_Main handleObbCallback];
            }

            CkUpdate();

            if (g_Main.canDraw) {
                // Apparently it can take a few frames for e.g. screen rotation
                // to kick in, even after we get notified. What a crock.
                // Let's just poll it every frame.
                [g_Main updateScreenSize];
                [g_Main updateGL:NO];
            }
        }
    }
}
