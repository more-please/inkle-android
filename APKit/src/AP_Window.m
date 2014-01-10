#import "AP_Window.h"

#import <OpenGLES/ES2/gl.h>

#import "AP_FPSCounter.h"
#import "AP_Touch.h"
#import "AP_Utils.h"

@implementation AP_Window {
    AP_ViewController* _rootViewController;
    AP_FPSCounter* _fps;
    double _clock;
    AP_View* _hitTestView;
    NSMutableSet* _activeTouches;
}

static CGSize g_ScreenSize = {320, 480};
static CGFloat g_ScreenScale = 1.0;

+ (CGRect) screenBounds
{
    return CGRectMake(0, 0, g_ScreenSize.width, g_ScreenSize.height);
}

+ (CGSize) screenSize
{
    return g_ScreenSize;
}

+ (CGFloat) screenScale
{
    return g_ScreenScale;
}

static float iPhoneDiagonal = 391.9183588453085; // sqrt(320 * 480)
static float iPadDiagonal = 886.8100134752651; // sqrt(1024 * 768)

+ (CGFloat) iPhone:(CGFloat)iPhone iPad:(CGFloat)iPad
{
    CGFloat deviceDiagonal = sqrt(g_ScreenSize.width * g_ScreenSize.height);
    CGFloat deviceRatio = (deviceDiagonal - iPhoneDiagonal) / (iPadDiagonal - iPhoneDiagonal);
    return AP_Lerp(iPhone, iPad, deviceRatio);
}

- (AP_Window*) init
{
    self = [super init];
    if (self) {
        _clock = AP_TimeInSeconds();
        _fps = [[AP_FPSCounter alloc] init];
        _fps.logInterval = 1;
        [AP_Animation setMasterClock:_clock];
        _activeTouches = [NSMutableSet set];
#ifdef ANDROID
        UIScreen* screen = [UIScreen mainScreen];
        g_ScreenSize = screen.bounds.size;
        g_ScreenScale = screen.scale;
        NSLog(@"Screen size %dx%d, density %.2f", (int) g_ScreenSize.width, (int) g_ScreenSize.height, g_ScreenScale);
#endif
    }
    return self;
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

#ifndef ANDROID
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
    g_ScreenSize = screen.bounds.size;
    if (isLandscape) {
        g_ScreenSize = CGSizeMake(g_ScreenSize.height, g_ScreenSize.width);
    }
    NSLog(@"Screen size %dx%d, density %.2f", (int) g_ScreenSize.width, (int) g_ScreenSize.height, g_ScreenScale);
}

- (void)dealloc
{
    [EAGLContext setCurrentContext:nil];
}
#endif

- (void) update
{
}

- (CGRect) bounds
{
    return CGRectMake(0, 0, g_ScreenSize.width, g_ScreenSize.height);
}

#ifndef ANDROID
- (void) glkView:(GLKView *)view drawInRect:(CGRect)r
{
    [self drawWithSize:view.bounds.size scale:[UIScreen mainScreen].scale];
}
#endif

- (void) draw
{
    UIScreen* screen = [UIScreen mainScreen];
    [self drawWithSize:screen.bounds.size scale:screen.scale];
}

- (void) drawWithSize:(CGSize)s scale:(CGFloat)scale
{
    _clock = AP_TimeInSeconds();
    [AP_Animation setMasterClock:_clock];

    glClearColor(1, 0, 0.5, 0);
    glClear(GL_COLOR_BUFFER_BIT);

    [_fps tick];

    if (scale != g_ScreenScale) {
        g_ScreenScale = scale;
    }

    if (!CGSizeEqualToSize(s, g_ScreenSize)) {
        NSLog(@"Screen size changed: was %dx%d, now %dx%d", (int) g_ScreenSize.width, (int) g_ScreenSize.height, (int) s.width, (int) s.height);
        g_ScreenSize = s;
        if (_rootViewController) {
            _rootViewController.view.frame = CGRectMake(0, 0, s.width, s.height);
        }
    }

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
            2.0 / s.width, 2.0 / s.height);

    glViewport(0, 0, s.width * scale, s.height * scale);

    if (_rootViewController) {
        AP_View* v = _rootViewController.view;
        [v visitWithBlock:^(AP_View* view) {
            [view updateGL];
        }];
    }

    for (AP_Animation* animation in [AP_Animation animations]) {
        [animation update];
    }

    if (_rootViewController) {
        AP_View* v = _rootViewController.view;
        [v renderSelfAndChildrenWithFrameToGL:frameToGL alpha:1];
    }
}

//------------------------------------------------------------------------------------
#pragma mark - Input
//------------------------------------------------------------------------------------

static NSSet* mapTouches(NSSet* touches) {
    NSMutableSet* result = [NSMutableSet set];
    for (UITouch* touch in touches) {
        [result addObject:touch.android];
    }
    return result;
}

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    for (UITouch* touch in touches) {
        [_activeTouches addObject:touch];
        CGPoint p = [touch locationInView:self.view];
        touch.android = [AP_Touch touchWithWindowPos:p];
        if (!_hitTestView) {
            _hitTestView = [_rootViewController.view hitTest:touch.android.windowPos withEvent:nil];
        }
    }
    if (_hitTestView) {
        [_hitTestView touchesBegan:mapTouches(touches) withEvent:nil];
    }
}

- (void) touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
    if (_hitTestView) {
        [_hitTestView touchesCancelled:mapTouches(touches) withEvent:nil];
    }
    for (UITouch* touch in touches) {
        [_activeTouches removeObject:touch];
    }
    if (_activeTouches.count == 0) {
        _hitTestView = nil;
    }
}

- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    if (_hitTestView) {
        [_hitTestView touchesEnded:mapTouches(touches) withEvent:nil];
    }
    for (UITouch* touch in touches) {
        [_activeTouches removeObject:touch];
    }
    if (_activeTouches.count == 0) {
        _hitTestView = nil;
    }
}

- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    for (UITouch* touch in touches) {
        CGPoint p = [touch locationInView:self.view];
        touch.android.windowPos = p;
    }
    if (_hitTestView) {
        [_hitTestView touchesMoved:mapTouches(touches) withEvent:nil];
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

- (void) didReceiveMemoryWarning
{
    if (_rootViewController) {
        [_rootViewController didReceiveMemoryWarning];
    }
}

#endif

@end
