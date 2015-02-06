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

static inline CGFloat aspect(CGSize size) {
    return size.width / size.height;
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
        _fps.logInterval = 10;
        _profiler.reportInterval = 60;
#endif
        [AP_Animation setMasterClock:_clock];
        _activeTouches = [NSMutableSet set];
#ifdef ANDROID
        UIScreen* screen = [UIScreen mainScreen];
        g_ScreenBounds = screen.bounds;
        g_ScreenScale = screen.scale;
        NSLog(@"Screen size %dx%d, density %.2f", (int) g_ScreenBounds.size.width, (int) g_ScreenBounds.size.height, g_ScreenScale);

        [[NSNotificationCenter defaultCenter]
            addObserver:self
            selector:@selector(didReceiveMemoryWarning)
            name:UIApplicationDidReceiveMemoryWarningNotification
            object:nil];
#endif
    }
    return self;
}

#ifdef ANDROID
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
#endif

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

#ifndef AP_REPLACE_UI
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.preferredFramesPerSecond = 30;

    GLKView *view = (GLKView *)self.view;
    view.multipleTouchEnabled = TRUE;
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    assert(view.context);
    view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.contentMode = UIViewContentModeRedraw;
    view.multipleTouchEnabled = TRUE;
    [EAGLContext setCurrentContext:view.context];

    // You might very well expect view.bounds to take the screen orientation into account,
    // but IT DOESN'T. As far as I can tell, if you launch in landscape mode, the root view
    // is initially portrait, then resized to landscape. ????!??
    UIScreen* screen = [UIScreen mainScreen];
    UIInterfaceOrientation orientation = self.interfaceOrientation;
    BOOL isLandscape = UIInterfaceOrientationIsLandscape(orientation);
    g_ScreenScale = screen.scale;
    g_ScreenBounds = screen.bounds;
    if (isLandscape) {
        g_ScreenBounds.origin = CGPointMake(g_ScreenBounds.origin.y, g_ScreenBounds.origin.x);
        g_ScreenBounds.size = CGSizeMake(g_ScreenBounds.size.height, g_ScreenBounds.size.width);
    }
    NSLog(@"Screen size %dx%d, density %.2f", (int) g_ScreenBounds.size.width, (int) g_ScreenBounds.size.height, g_ScreenScale);
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [EAGLContext setCurrentContext:nil];
}
#endif

- (void) update
{
}

- (CGRect) bounds
{
    return g_ScreenBounds;
}

#ifndef ANDROID
- (void) glkView:(GLKView *)view drawInRect:(CGRect)r
{
    [self draw];
}
#endif

- (void) draw
{
    [AP_GLTexture processDeleteQueue];
    [AP_GLBuffer processDeleteQueue];

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

    if (scale != g_ScreenScale) {
        g_ScreenScale = scale;
    }

    if (!CGRectEqualToRect(bounds, g_ScreenBounds)) {
        NSLog(@"Screen size changed: was %dx%d, now %dx%d", (int) g_ScreenBounds.size.width, (int) g_ScreenBounds.size.height, (int) bounds.size.width, (int) bounds.size.height);
        g_ScreenBounds = bounds;
        [[NSNotificationCenter defaultCenter] postNotificationName:AP_ScreenSizeChangedNotification object:nil];
        if (_rootViewController) {
            [_rootViewController.view visitControllersWithBlock:^(AP_ViewController* c) {
                [c willRotateToInterfaceOrientation:c.interfaceOrientation duration:0];
            }];
            _rootViewController.view.frame = bounds;
            [_rootViewController.view visitWithBlock:^(AP_View* v) {
                [v setNeedsLayout];
            }];
        }
    }

    [_profiler step:@"update"];
    BOOL needsDisplay = NO;
    BOOL* needsDisplayPtr = &needsDisplay;
    if (_rootViewController) {
        AP_View* v = _rootViewController.view;
        [v visitControllersWithBlock:^(AP_ViewController* c) {
            [c updateGL:dt];
        }];
        [v visitWithBlock:^(AP_View* view) {
            [view updateGL:dt];
            if (view.takeNeedsDisplay) {
                *needsDisplayPtr = YES;
            }
        }];
    }

#ifdef ANDROID
    if (needsDisplay) {
        self.idleFrameCount = 0;
    } else {
        self.idleFrameCount += 1;
    }
#endif

    [_profiler step:@"layout"];
    if (_rootViewController) {
        [_rootViewController.view layoutIfNeeded];
    }

    [_profiler step:@"clear"];
#ifdef ANDROID
    _GL(BindFramebuffer, GL_FRAMEBUFFER, 0);
#endif
    _GL(Viewport, 0, 0, bounds.size.width * scale, bounds.size.height * scale);
    _GL(Disable, GL_DEPTH_TEST);
    _GL(Enable, GL_BLEND);
    _GL(BlendFunc, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    _GL(Disable, GL_SCISSOR_TEST);
    _GL(ClearColor, 0, 0, 0, 0);
    _GL(ClearStencil, 0);
    _GL(Clear, GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    _GL(Enable, GL_SCISSOR_TEST);

    // Make sure we notice if somebody enables depth-testing!
    _GL(DepthFunc, GL_NEVER);

    [AP_Window setScissorRect:CGRectMake(-1, -1, 2, 2)];

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

    [_profiler step:@"other"];
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

- (void) dispatchGestureWithBlock:(void(^)(AP_GestureRecognizer*))block
{
    if (_hitTestView && _hitTestView.window != self) {
        NSLog(@"*** lost the hit test view! ***");
    }

    for (AP_View* v = _hitTestView; v; v = v.superview) {
        for (AP_GestureRecognizer* g in v.gestureRecognizers) {
            if (g == _hitTestGesture) {
                // This is the hit test gesture. It always gets to run.
                block(g);
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
                block(g);
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
    [self dispatchGestureWithBlock:^(AP_GestureRecognizer*g) {
        [g touchesBegan:touches withEvent:event];
    }];
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

    [self dispatchGestureWithBlock:^(AP_GestureRecognizer*g) {
        [g touchesCancelled:touches withEvent:event];
    }];
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

    [self dispatchGestureWithBlock:^(AP_GestureRecognizer*g) {
        [g touchesEnded:touches withEvent:event];
    }];
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

    [self dispatchGestureWithBlock:^(AP_GestureRecognizer*g) {
        [g touchesMoved:touches withEvent:event];
    }];
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

- (void) didReceiveMemoryWarning
{
    if (_rootViewController) {
        AP_View* v = _rootViewController.view;
        [v visitControllersWithBlock:^(AP_ViewController* c) {
            [c didReceiveMemoryWarning];
        }];
    }
}

#ifndef ANDROID

//------------------------------------------------------------------------------------
#pragma mark - Delegated UIViewController methods
//------------------------------------------------------------------------------------

- (BOOL) shouldAutorotate
{
    return YES;
}

- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void) viewDidLayoutSubviews
{
    if (_rootViewController) {
        _rootViewController.view.frame = self.bounds;
    }
}

#endif

@end
