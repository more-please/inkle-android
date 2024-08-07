#import "AP_Window.h"

#import <OpenGLES/ES2/gl.h>

#import "AP_Check.h"
#import "AP_FPSCounter.h"
#import "AP_GLBuffer.h"
#import "AP_GLTexture.h"
#import "AP_Profiler.h"
#import "AP_Touch.h"
#import "AP_Utils.h"

NSString* const AP_ScreenSizeChangedNotification = @"AP_ScreenSizeChangedNotification";

@implementation AP_Window {
    AP_ViewController* _rootViewController;
    AP_FPSCounter* _fps;
    AP_Profiler* _profiler;
    double _clock;
    __weak AP_View* _hoverView;
    AP_View* _hitTestView;
    AP_GestureRecognizer* _hitTestGesture;
    NSMutableSet* _activeTouches;
}

- (BOOL) isHitTestView:(AP_View *)view
{
    return view == _hitTestView;
}

- (BOOL) isGestureView:(AP_View *)view
{
    return view == _hitTestGesture.view;
}

- (BOOL) isHoverView:(AP_View*)view
{
    return view == _hoverView;
}

static CGRect g_AppFrame = {0, 0, 320, 480};
static CGRect g_ScreenBounds = {0, 0, 320, 480};
static CGFloat g_ScreenScale = 1.0;
static CGRect g_ScissorRect;

+ (CGRect) screenBounds
{
    return g_ScreenBounds;
}

+ (CGSize) screenSize
{
    return g_ScreenBounds.size;
}

+ (CGFloat) screenScale
{
    return g_ScreenScale;
}

+ (CGRect) overlayScissorRect:(CGRect)r
{
    r = CGRectIntersection(g_ScissorRect, r);
    return [AP_Window setScissorRect:r];
}

+ (CGRect) setScissorRect:(CGRect)r
{
    CGRect previous = g_ScissorRect;
    g_ScissorRect = r;

    // Scale from GL coordinates (-1, -1, 2, 2) to screen coordinates.
    CGPoint scale = {
        g_ScreenScale * g_ScreenBounds.size.width / 2,
        g_ScreenScale * g_ScreenBounds.size.height / 2
    };
    int x0 = (r.origin.x + 1) * scale.x;
    int y0 = (r.origin.y + 1) * scale.y;
    int x1 = x0 + MAX(0, r.size.width * scale.x);
    int y1 = y0 + MAX(0, r.size.height * scale.y);
    _GL(Scissor, x0, y0, x1 - x0, y1 - y0);

    return previous;
}

static const CGSize iPhonePortrait = { 320, 480 };
static const CGSize iPhoneLandscape = { 480, 320 };
static const CGSize iPadPortrait = { 768, 1024 };
static const CGSize iPadLandscape = { 1024, 768 };

+ (CGFloat) widthForIPhone:(CGFloat)iPhone iPad:(CGFloat)iPad
{
    CGFloat widthRatio = (g_ScreenBounds.size.width > g_ScreenBounds.size.height)
        ? (g_ScreenBounds.size.width - iPhoneLandscape.width) / (iPadLandscape.width - iPhoneLandscape.width)
        : (g_ScreenBounds.size.width - iPhonePortrait.width) / (iPadPortrait.width - iPhonePortrait.width);
    CGFloat result = AP_Lerp(iPhone, iPad, widthRatio);
    return result;
}

+ (CGFloat) heightForIPhone:(CGFloat)iPhone iPad:(CGFloat)iPad
{
    CGFloat heightRatio = (g_ScreenBounds.size.width > g_ScreenBounds.size.height)
        ? (g_ScreenBounds.size.height - iPhoneLandscape.height) / (iPadLandscape.height - iPhoneLandscape.height)
        : (g_ScreenBounds.size.height - iPhonePortrait.height) / (iPadPortrait.height - iPhonePortrait.height);
    CGFloat result = AP_Lerp(iPhone, iPad, heightRatio);
    return result;
}

static inline CGFloat side(CGSize size) {
    return sqrt(size.width * size.height);
}

+ (CGFloat) scaleForIPhone:(CGFloat)iPhone iPad:(CGFloat)iPad
{
    // Ensure negative values are handled correctly.
    if (iPhone < 0 && iPad < 0) {
        return -[AP_Window scaleForIPhone:-iPhone iPad:-iPad];
    }
    // Ensure we're scaling *up* from iPhone to iPad.
    if (iPhone > iPad) {
        if (iPad > 0) {
            return 1.0 / [AP_Window scaleForIPhone:1.0/iPhone iPad:1.0/iPad];
        } else {
            return iPhone - [AP_Window scaleForIPhone:iPad iPad:iPhone];
        }
    }
    CGFloat sizeRatio = (side(g_ScreenBounds.size) - side(iPhonePortrait)) / (side(iPadPortrait) - side(iPhonePortrait));
    CGFloat result = AP_Lerp(iPhone, iPad, sizeRatio);
    return result;
}

+ (CGFloat) iPhone:(CGFloat)iPhone iPad:(CGFloat)iPad iPadLandscape:(CGFloat)iPadLandscape iPhone6:(CGFloat)i6
{
    // Ignore the iPhone 6 for now
    return [AP_Window iPhone:iPhone iPad:iPad iPadLandscape:iPadLandscape];
}

+ (CGFloat) iPhone:(CGFloat)iPhone iPad:(CGFloat)iPad iPadLandscape:(CGFloat)iPadLandscape
{
    CGFloat iPhoneLandscape = (iPad == 0) ? (iPadLandscape + iPhone - iPad) : (iPadLandscape * iPhone / iPad);
    BOOL isLandscape = (g_ScreenBounds.size.width > g_ScreenBounds.size.height);

    // The game here is to figure out whether the landscape value is based on
    // the screen's width or height. We assume if the value is smaller, it's
    // based on the smaller screen edge.
    CGFloat result;
    if (iPadLandscape < iPad) {
        // Landscape value is smaller -> this is a height metric.
        if (isLandscape) {
            result = [AP_Window heightForIPhone:iPhoneLandscape iPad:iPadLandscape];
        } else {
            result = [AP_Window heightForIPhone:iPhone iPad:iPad];
        }
    } else {
        // Landscape value is higher -> this is a width metric.
        if (isLandscape) {
            result = [AP_Window widthForIPhone:iPhoneLandscape iPad:iPadLandscape];
        } else {
            result = [AP_Window widthForIPhone:iPhone iPad:iPad];
        }
    }
//    NSLog(@"Metric for iPhone:%.3f iPad:%.3f landscape:%.3f -> iPhoneLandscape:%.3f result:%.3f", iPhone, iPad, iPadLandscape, iPhoneLandscape, result);
    return result;
}

static NSMutableArray* s_afterFrameBlocks;

+ (void) performAfterFrame:(AfterFrameBlock)block
{
    if (!s_afterFrameBlocks) {
        s_afterFrameBlocks = [NSMutableArray array];
    }
    [s_afterFrameBlocks addObject:block];
}

+ (void) runAfterFrameHooks
{
    NSArray* blocks = s_afterFrameBlocks;
    s_afterFrameBlocks = nil;
    if (blocks) {
        for (AfterFrameBlock block in blocks) {
            block();
        }
    }
}

- (AP_Window*) init
{
    self = [super init];
    if (self) {
        _clock = AP_TimeInSeconds();
        _fps = [[AP_FPSCounter alloc] init];
        _profiler = [[AP_Profiler alloc] init];
#ifdef DEBUG
        _fps.logInterval = 1;
        _profiler.reportInterval = 5;
#else
//        _fps.logInterval = 5;
//        _profiler.reportInterval = 30;
#endif
        [AP_Animation setMasterClock:_clock];
        _activeTouches = [NSMutableSet set];

        UIScreen* screen = [UIScreen mainScreen];
        g_AppFrame = screen.applicationFrame;
        g_ScreenBounds = screen.bounds;
        g_ScreenScale = screen.scale;
        NSLog(@"Screen size %dx%d, density %.2f", (int) g_ScreenBounds.size.width, (int) g_ScreenBounds.size.height, g_ScreenScale);

        [[NSNotificationCenter defaultCenter]
            addObserver:self
            selector:@selector(didReceiveMemoryWarning)
            name:UIApplicationDidReceiveMemoryWarningNotification
            object:nil];
    }
    return self;
}

- (void)dealloc
{
    [AP_Window runAfterFrameHooks];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (AP_ViewController*) rootViewController
{
    return _rootViewController;
}

- (void) setRootViewController:(AP_ViewController*)controller
{
    if (_rootViewController && _rootViewController.view) {
        _rootViewController.view.window = nil;
    }
    _rootViewController = controller;
    if (controller && controller.view) {
        controller.view.window = self;
    }
}

- (CGRect) bounds
{
    return g_ScreenBounds;
}

- (void) resetGL
{
    _GL(BlendColor, 0, 0, 0, 0);
    _GL(BlendEquation, GL_FUNC_ADD);
    _GL(BlendFunc, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    _GL(ColorMask, GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    _GL(CullFace, GL_BACK);
    _GL(DepthFunc, GL_LESS);
    _GL(DepthMask, GL_TRUE);
    _GL(DepthRangef, 0, 1);

    // See http://docs.gl/es2/glEnable - all initially false except GL_DITHER
    _GL(Disable, GL_BLEND);
    _GL(Disable, GL_CULL_FACE);
    _GL(Disable, GL_DEPTH_TEST);
    _GL(Enable, GL_DITHER);
    _GL(Disable, GL_POLYGON_OFFSET_FILL);
    _GL(Disable, GL_SAMPLE_ALPHA_TO_COVERAGE);
    _GL(Disable, GL_SAMPLE_COVERAGE);
    _GL(Disable, GL_SCISSOR_TEST);
    _GL(Disable, GL_STENCIL_TEST);

    _GL(FrontFace, GL_CCW);
    _GL(LineWidth, 1);
    _GL(PixelStorei, GL_PACK_ALIGNMENT, 4);
    _GL(PixelStorei, GL_UNPACK_ALIGNMENT, 4);
    _GL(PolygonOffset, 0, 0);
    _GL(SampleCoverage, 1, GL_FALSE);
    _GL(StencilFunc, GL_ALWAYS, 0, (GLuint) -1);
    _GL(StencilMask, (GLuint) -1);
    _GL(StencilOp, GL_KEEP, GL_KEEP, GL_KEEP);

    // Skip these as they depend on the size of the window
    // _GL(Scissor, 0, 0, width, height);
    // _GL(Viewport, 0, 0, width, height);

    _GL(ClearColor, 0, 0, 0, 0);
#ifdef GL_ES_VERSION_2_0
    _GL(ClearDepthf, 1);
#else
    _GL(ClearDepth, 1);
#endif
    _GL(ClearStencil, 0);
}

- (BOOL) update
{
    const double t = AP_TimeInSeconds();
    const float minFrameTime = 1.0 / 120;
    const float maxFrameTime = 1.0 / 10;
    const float dt = MAX(minFrameTime, MIN(maxFrameTime, t - _clock));
    _clock = t;

    [AP_Animation setMasterClock:_clock];
    [_fps tick];
    [_profiler maybeReport];

    [_profiler step:@"animation"];
    for (AP_Animation* animation in [AP_Animation animations]) {
        [animation update];
    }

    [_profiler step:@"resize"];
    UIScreen* screen = [UIScreen mainScreen];
    float scale = screen.scale;
    CGRect bounds = screen.bounds;
    CGRect appFrame = screen.applicationFrame;

    if (scale != g_ScreenScale) {
        g_ScreenScale = scale;
    }

    if (!CGRectEqualToRect(bounds, g_ScreenBounds) || !CGRectEqualToRect(appFrame, g_AppFrame)) {
        NSLog(@"Screen (or status bar) size changed: was %dx%d, now %dx%d", (int) g_ScreenBounds.size.width, (int) g_ScreenBounds.size.height, (int) bounds.size.width, (int) bounds.size.height);
        g_ScreenBounds = bounds;
        g_AppFrame = appFrame;
        [[NSNotificationCenter defaultCenter] postNotificationName:AP_ScreenSizeChangedNotification object:nil];
        if (_rootViewController) {
            VoidViewControllerBlock vcb = ^(AP_ViewController* c) {
                [c willRotateToInterfaceOrientation:c.interfaceOrientation duration:0];
            };
            [_rootViewController.view visitControllersWithBlock:&vcb];

            _rootViewController.view.frame = bounds;
            VoidViewBlock vb = ^(AP_View* v) {
                [v setNeedsLayout];
            };
            [_rootViewController.view visitWithBlock:&vb];
        }
    }

    [AP_Window runAfterFrameHooks];

    [_profiler step:@"update"];

    [AP_GLTexture processDeleteQueue];
    [AP_GLBuffer processDeleteQueue];

    [self resetGL];

    _GL(Enable, GL_BLEND);

    BOOL needsDisplay = NO;
    BOOL* needsDisplayPtr = &needsDisplay;
    if (_rootViewController) {
        AP_View* v = _rootViewController.view;

        VoidViewControllerBlock vcb = ^(AP_ViewController*c) {
            [c updateGL:dt];
        };
        [v visitControllersWithBlock:&vcb];

        VoidViewBlock vb = ^(AP_View* view) {
            [view updateGL:dt];
            if (view.takeNeedsDisplay) {
                *needsDisplayPtr = YES;
            }
        };
        [v visitWithBlock:&vb];
    }

    return needsDisplay;
}

- (void) draw
{
    [_profiler step:@"layout"];
    if (_rootViewController) {
        [_rootViewController.view layoutIfNeeded];
    }

    CGRect bounds = g_ScreenBounds;
    CGFloat scale = g_ScreenScale;

    [_profiler step:@"clear"];

    [self resetGL];

#if defined(SORCERY_SDL) || defined(ANDROID)
    _GL(BindFramebuffer, GL_FRAMEBUFFER, 0);
#endif
    _GL(Viewport, 0, 0, bounds.size.width * scale, bounds.size.height * scale);

    _GL(Clear, GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

    [AP_Window setScissorRect:CGRectMake(-1, -1, 2, 2)];

    _GL(Enable, GL_BLEND);
    _GL(Enable, GL_SCISSOR_TEST);

    // To transform from UIView coordinates to glViewport coordinates (-1, -1, 2, 2):
    // - scale from screen size to (2, 2).
    // - translate from (0, 0) to (-1, -1).
    // - flip vertically.

    CGAffineTransform frameToGL =
        CGAffineTransformScale(
            CGAffineTransformTranslate(
                CGAffineTransformScale(
                    CGAffineTransformIdentity,
                    1.0, -1.0),
                -1.0, -1.0),
            2.0 / bounds.size.width, 2.0 / bounds.size.height);

    [_profiler step:@"render"];
    if (_rootViewController) {
        AP_View* v = _rootViewController.view;
        [v renderSelfAndChildrenWithFrameToGL:frameToGL alpha:1];
    }
}

//------------------------------------------------------------------------------------
#pragma mark - Input
//------------------------------------------------------------------------------------

- (void) resetAllGestures
{
    if (_hitTestGesture) {
        [_hitTestGesture reset];
        _hitTestGesture = nil;
    }
    for (AP_View* v = _hitTestView; v; v = v.superview) {
        for (AP_GestureRecognizer* g in v.gestureRecognizers) {
            [g reset];
        }
    }
    if (_hitTestView) {
        [_hitTestView touchesCancelled:_activeTouches withEvent:nil];
    }
    _hitTestView = nil;
}

static BOOL isActive(AP_GestureRecognizer* g) {
    UIGestureRecognizerState state = g.state;
    return (state == UIGestureRecognizerStateBegan)
        || (state == UIGestureRecognizerStateChanged);
}

typedef void (^GestureBlock)(AP_GestureRecognizer*);

- (void) dispatchGestureWithBlock:(GestureBlock*)block
{
    if (_hitTestView && _hitTestView.window != self) {
        NSLog(@"*** lost the hit test view! ***");
    }

    for (AP_View* v = _hitTestView; v; v = v.superview) {
        for (AP_GestureRecognizer* g in v.gestureRecognizers) {
            if (g == _hitTestGesture) {
                // This is the hit test gesture. It always gets to run.
                (*block)(g);
                if (!isActive(g)) {
                    _hitTestGesture = nil;
                }
            } else {
                // If there's another hit test gesture, it could block us.
                if (_hitTestGesture
                    && ![_hitTestGesture shouldRecognizeSimultaneouslyWithGestureRecognizer:g]
                    && ![g shouldRecognizeSimultaneouslyWithGestureRecognizer:_hitTestGesture]) {
                    if (isActive(g)) {
                        [g reset];
                    }
                    continue;
                }
                (*block)(g);
                if (!_hitTestGesture && isActive(g)) {
                    _hitTestGesture = g;
                }
            }
        }
        if (v.blockGestures) {
            break;
        }
    }
}

- (void) touchesBegan:(NSSet*)ts withEvent:(Real_UIEvent*)e
{
    NSMutableSet* touches = [NSMutableSet set];
    for (Real_UITouch* t in ts) {
        CGPoint p = [t locationInView:self.view];
        AP_Touch* touch = [AP_Touch touchWithWindowPos:p];
        t.android = touch;
        touch.phase = UITouchPhaseBegan;
        [_activeTouches addObject:touch];
        [touches addObject:touch];
    }
    AP_Event* event = [[AP_Event alloc] init];
    event.timestamp = e.timestamp;
    event.allTouches = _activeTouches;

    for (AP_Touch* touch in touches) {
        if (!_hitTestView) {
            _hitTestView = [_rootViewController.view hitTest:touch.windowPos withEvent:event];
        }
    }
    GestureBlock b = ^(AP_GestureRecognizer*g) {
        [g touchesBegan:touches withEvent:event];
    };
    [self dispatchGestureWithBlock:&b];
    if (_hitTestView) {
        [_hitTestView touchesBegan:touches withEvent:event];
    }
}

- (void) touchesCancelled:(NSSet*)ts withEvent:(Real_UIEvent*)e
{
    NSMutableSet* touches = [NSMutableSet set];
    for (Real_UITouch* t in ts) {
        if (!t.android) {
            NSLog(@"Touches out of sync!");
            [self resetTouches];
            return;
        }
        t.android.phase = UITouchPhaseCancelled;
        [touches addObject:t.android];
    }
    AP_Event* event = [[AP_Event alloc] init];
    event.timestamp = e.timestamp;
    event.allTouches = _activeTouches;

    GestureBlock b = ^(AP_GestureRecognizer*g) {
        [g touchesCancelled:touches withEvent:event];
    };
    [self dispatchGestureWithBlock:&b];
    if (_hitTestView) {
        [_hitTestView touchesCancelled:touches withEvent:event];
    }

    for (AP_Touch* touch in touches) {
        [_activeTouches removeObject:touch];
    }
    if (_activeTouches.count == 0) {
        _hitTestView = nil;
        _hitTestGesture = nil;
    }
}

- (void) touchesEnded:(NSSet*)ts withEvent:(Real_UIEvent*)e
{
    NSMutableSet* touches = [NSMutableSet set];
    for (Real_UITouch* t in ts) {
        if (!t.android) {
            NSLog(@"Touches out of sync!");
            [self resetTouches];
            return;
        }
        t.android.phase = UITouchPhaseEnded;
        [touches addObject:t.android];
    }
    AP_Event* event = [[AP_Event alloc] init];
    event.timestamp = e.timestamp;
    event.allTouches = _activeTouches;

    GestureBlock b = ^(AP_GestureRecognizer*g) {
        [g touchesEnded:touches withEvent:event];
    };
    [self dispatchGestureWithBlock:&b];
    if (_hitTestView) {
        [_hitTestView touchesEnded:touches withEvent:event];
    }

    for (AP_Touch* touch in touches) {
        [_activeTouches removeObject:touch];
    }
    if (_activeTouches.count == 0) {
        _hitTestView = nil;
        _hitTestGesture = nil;
    }
}

- (void) touchesMoved:(NSSet*)ts withEvent:(Real_UIEvent*)e
{
    for (AP_Touch* touch in _activeTouches) {
        touch.phase = UITouchPhaseStationary;
    }

    NSMutableSet* touches = [NSMutableSet set];
    for (Real_UITouch* t in ts) {
        if (!t.android) {
            NSLog(@"Touches out of sync!");
            [self resetTouches];
            return;
        }
        t.android.windowPos = [t locationInView:self.view];
        t.android.phase = UITouchPhaseMoved;
        [touches addObject:t.android];
    }
    AP_Event* event = [[AP_Event alloc] init];
    event.timestamp = e.timestamp;
    event.allTouches = _activeTouches;

    GestureBlock b = ^(AP_GestureRecognizer*g) {
        [g touchesMoved:touches withEvent:event];
    };
    [self dispatchGestureWithBlock:&b];
    if (_hitTestView) {
        [_hitTestView touchesMoved:touches withEvent:event];
    }
}

- (void) resetTouches
{
    for (AP_Touch* touch in _activeTouches) {
        touch.phase = UITouchPhaseCancelled;
    }
    for (AP_View* v = _hitTestView; v; v = v.superview) {
        for (AP_GestureRecognizer* g in _hitTestView.gestureRecognizers) {
            [g reset];
        }
    }
    _hitTestView = nil;
    _hitTestGesture = nil;
    _activeTouches = [NSMutableSet set];
}

- (void) mouseMoved:(CGPoint)pos withEvent:(Real_UIEvent*)event
{
    AP_View* oldHoverView = _hoverView;
    AP_View* newHoverView = [_rootViewController.view hitTest:pos withEvent:nil];
    if (newHoverView != oldHoverView) {
        [oldHoverView mouseLeave];
        _hoverView = newHoverView;
        [newHoverView mouseEnter];
    }
}

- (void) didReceiveMemoryWarning
{
    if (_rootViewController) {
        AP_View* v = _rootViewController.view;
        VoidViewControllerBlock vcb = ^(AP_ViewController* c) {
            [c didReceiveMemoryWarning];
        };
        [v visitControllersWithBlock:&vcb];
    }
}

@end
