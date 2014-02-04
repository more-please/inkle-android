#import <APKit/APKit.h>

#import <jni.h>
#import <errno.h>

#import <EGL/egl.h>
#import <GLES2/gl2.h>

#import <android/log.h>
#import <android/sensor.h>
#import <android/storage_manager.h>
#import <android_native_app_glue.h>

#import <ck/ck.h>
#import "SorceryAppDelegate.h"

@interface Main : AP_Application
@property(nonatomic,readonly) BOOL active;
@end

static Main* g_Main;
static void obbCallback();
static volatile BOOL g_NeedToCheckObb;

static JNINativeMethod g_NativeMethods[] = {
    {"obbCallback", "()V", (void*)&obbCallback},
};

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
static JavaMethod kMountObb = {
    "mountObb", "()Ljava/lang/String;", NULL
};
static JavaMethod kGetScreenInfo = {
    "getScreenInfo", "()[F", NULL
};
static JavaMethod kPleaseFinish = {
    "pleaseFinish", "()V", NULL
};

@implementation Main {
    struct android_app* _android;

    AStorageManager* _storageManager;
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

        _storageManager = AStorageManager_new();
        AP_CHECK(_storageManager, return nil);

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
        CkInit(&config);

        // Get SorceryActivity and its methods.
        _instance = _env->NewGlobalRef(_android->activity->clazz);
        AP_CHECK(_instance, return nil);

        _class = _env->GetObjectClass(_instance);
        AP_CHECK(_class, return nil);

        // Register our own methods.
        result = _env->RegisterNatives(_class, g_NativeMethods, 1);
        AP_CHECK(result == JNI_OK, return nil);

        self.documentsDir = [self javaStringMethod:&kGetDocumentsDir];
        NSLog(@"documentsDir: %@", self.documentsDir);

        // Mount the expansion file.
        _obbPath = [self javaStringMethod:&kMountObb];
        NSLog(@"obbPath: %@", _obbPath);

        _touches = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void) dealloc
{
    [self teardownGL];
    [self teardownJava];
    g_Main = nil;
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

- (BOOL) active
{
    return _inForeground && _surface;
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

    NSLog(@"Let's get started!");

    [AP_Bundle mainBundle].root = _mountPath;

    NSString* pakPath = [_mountPath stringByAppendingPathComponent:@"sorcery1_android.pak"];
    AP_PakReader* pak = [AP_PakReader readerWithMemoryMappedFile:pakPath];
    [AP_Bundle addPak:pak];

    SorceryAppDelegate* sorcery = [[SorceryAppDelegate alloc] init];
    self.delegate = sorcery;

    NSDictionary* options = [NSDictionary dictionary];
    [sorcery application:g_Main didFinishLaunchingWithOptions:options];
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

static void obbCallback() {
    // This may occur in the wrong thread, so don't call
    // handleObbCallback right away. Instead, set a flag
    // and let the main loop handle it.
    g_NeedToCheckObb = YES;
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
        [vc draw];
        eglSwapBuffers(_display, _surface);
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
                [self maybeInitApp];
                [self maybeInitSurface];
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
            while (1) {
                // Run Objective-C timers.
                // TODO: maybe factor limitDate into our polling timeout.
                [[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];

                // Read all pending events.
                struct android_poll_source* source;
                int timeout = g_Main.active ? 0 : -1;
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

            if (g_Main.active) {
                // Apparently it can take a few frames for e.g. screen rotation
                // to kick in, even after we get notified. What a crock.
                // Let's just poll it every frame.
                [g_Main updateScreenSize];
                [g_Main updateGL:NO];
            }
        }
    }
}
