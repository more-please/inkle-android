#import "AP_PageViewController.h"

#import "AP_Check.h"
#import "AP_Utils.h"
#import "AP_Window.h"

@interface AP_PageView : AP_View
// -1 if the middle page is over the left page.
// +1 if the middle page is over the right page.
@property (nonatomic) CGFloat position;
@property (nonatomic) UIPageViewControllerSpineLocation spineLocation;

@property (nonatomic,readonly) AP_View* leftPage;
@property (nonatomic,readonly) AP_View* midPage;
@property (nonatomic,readonly) AP_View* rightPage;
@end

@implementation AP_PageView

- (void) setLeft:(AP_View*)left mid:(AP_View*)mid right:(AP_View*)right
{
    [self replaceOldPage:_leftPage withNewPage:left];
    [self replaceOldPage:_rightPage withNewPage:right];
    [self replaceOldPage:_midPage withNewPage:mid];

    _leftPage = left;
    _midPage = mid;
    _rightPage = right;

    if (_midPage) {
        [self bringSubviewToFront:_midPage];
    }

    _position = 1;
    [self setNeedsLayout];
}

- (void) addOnLeft:(AP_View*)left
{
    [self replaceOldPage:_rightPage withNewPage:left];

    _rightPage = _midPage;
    _midPage = _leftPage;
    _leftPage = left;

    if (_midPage) {
        [self bringSubviewToFront:_midPage];
    }

    _position -= 2;
    [self setNeedsLayout];
}

- (void) addOnRight:(AP_View*)right
{
    [self replaceOldPage:_leftPage withNewPage:right];

    _leftPage = _midPage;
    _midPage = _rightPage;
    _rightPage = right;

    if (_midPage) {
        [self bringSubviewToFront:_midPage];
    }

    _position += 2;
    [self setNeedsLayout];
}

- (void) replaceOldPage:(AP_View*)oldPage withNewPage:(AP_View*)newPage
{
    if (oldPage) {
        [oldPage removeFromSuperview];
        [oldPage.viewDelegate removeFromParentViewController];
    }
    if (newPage) {
        [self addSubview:newPage];
        [self.viewDelegate addChildViewController:newPage.viewDelegate];
    }
}

- (void) setPosition:(CGFloat)p
{
    _position = p;
    [self setNeedsLayout];
}

// Logistic function centered around (0,0)
static CGFloat logistic(CGFloat x) {
    return 1.0f / (1.0f + expf(-x)) - 0.5f;
}

- (void) layoutSubviews
{
    CGRect r = self.bounds;
    CGRect left = r, right = r;
    switch (_spineLocation) {
        case UIPageViewControllerSpineLocationMin:
            left.origin.x -= r.size.width;
            break;

        case UIPageViewControllerSpineLocationMax:
            right.origin.x += r.size.width;
            break;

        case UIPageViewControllerSpineLocationMid:
        default:
            left.size.width /= 2;
            right.size.width /= 2;
            right.origin.x += right.size.width;
            break;
    }

    CGRect mid = left;

    // Apply a logistic function to make the page move faster in the middle.
    const CGFloat steepness = 2;
    CGFloat offset = logistic(_position * steepness) / logistic(steepness);
    offset = AP_CLAMP(offset, -1, 1);

    mid.origin.x = AP_Lerp(left.origin.x, right.origin.x, 0.5f + 0.5f * offset);
    
    // Pop the middle page out a little when it's close to the center.
    CGFloat pop = 1.0f - offset * offset; // 0 at the endpoints, 1 in the center.
    CGFloat scale = 1.0f + 0.05f * pop;
    _midPage.transform = CGAffineTransformMakeScale(scale, scale);

    _leftPage.transform = CGAffineTransformIdentity;
    _rightPage.transform = CGAffineTransformIdentity;

    _leftPage.frame = left;
    _midPage.frame = mid;
    _rightPage.frame = right;
}
@end

@implementation AP_PageViewController {
    BOOL _inGesture;
    CGFloat _previousTranslation;
    CGFloat _nextTranslation;
    CGFloat _velocity;
}

AP_BAN_EVIL_INIT;

- (id) initWithTransitionStyle:(UIPageViewControllerTransitionStyle)style navigationOrientation:(UIPageViewControllerNavigationOrientation)navigationOrientation options:(NSDictionary*)options
{
    self = [super init];
    if (self) {
        // ignore style, we'll just try our best
        // ignore orientation, assume horizontal
        NSNumber* spine = [options objectForKey:UIPageViewControllerOptionSpineLocationKey];
        _spineLocation = spine ? spine.intValue : UIPageViewControllerSpineLocationMin;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenSizeChanged) name:AP_ScreenSizeChangedNotification object:nil];
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) screenSizeChanged
{
    CGSize size = [UIScreen mainScreen].bounds.size;
    UIInterfaceOrientation orientation = (size.width > size.height) ? UIInterfaceOrientationLandscapeLeft : UIInterfaceOrientationPortrait;
    _spineLocation = [_delegate pageViewController:self spineLocationForInterfaceOrientation:orientation];
    AP_PageView* view = (AP_PageView*) self.view;
    view.spineLocation = _spineLocation;
}

- (void) loadView
{
    AP_PageView* view = [[AP_PageView alloc] init];
    view.spineLocation = _spineLocation;

    AP_PanGestureRecognizer* gesture = [[AP_PanGestureRecognizer alloc] initWithTarget:self action:@selector(pagePannedWithRecognizer:)];
    gesture.preventVerticalMovement = YES;
    [view addGestureRecognizer:gesture];

    self.view = view;
}

- (void) pagePannedWithRecognizer:(AP_PanGestureRecognizer*)pan
{
    UIGestureRecognizerState state = pan.state;
    if (state == UIGestureRecognizerStateBegan) {
        _inGesture = YES;
        _previousTranslation = [pan translationInView:nil].x;
        _nextTranslation = _previousTranslation;
    } else if (state == UIGestureRecognizerStateChanged) {
        _nextTranslation = [pan translationInView:nil].x;
    } else {
        _inGesture = NO;
    }
}

- (void) updateGL
{
    // Measure the time step since the previous call
    static double previousTime = 0;
    double time = CACurrentMediaTime();
    double timeStep = MAX(0.01, MIN(1, time - previousTime));
    previousTime = time;

    AP_PageView* view = (AP_PageView*) self.view;

    if (_inGesture) {
        CGFloat delta = _nextTranslation - _previousTranslation;
        _previousTranslation = _nextTranslation;

        delta /= view.midPage.bounds.size.width;
        delta *= 2;
        _velocity = delta;
        NSLog(@"prev = %1.f, next = %.1f, delta = %.1f, v = %.3f",
            _previousTranslation, _nextTranslation, delta, _velocity);
    }

    // Get the current velocity per second (not per frame!)
    float vCurrent = fabs(_velocity / timeStep);
    if (vCurrent > 0) {
        view.position += _velocity;
        NSLog(@"Position is now: %.3f", view.position);

        if (view.position < -1) {
            AP_PageViewController* newPage = [_dataSource pageViewController:self viewControllerAfterViewController:view.rightPage.viewDelegate];
            if (view.rightPage && newPage) {
                [view addOnRight:newPage.view];
            } else {
                view.position = -1;
            }
        } else if (view.position > 1) {
            AP_PageViewController* newPage = [_dataSource pageViewController:self viewControllerBeforeViewController:view.leftPage.viewDelegate];
            if (view.leftPage && newPage) {
                [view addOnLeft:newPage.view];
            } else {
                view.position = 1;
            }
        }

        // Velocity decay
        static const float kMinSpeed = 0.001;
        static const float kDeceleration = 5;
        float decay = exp(-kDeceleration * timeStep);
        float vNext = (vCurrent + kMinSpeed) * decay - kMinSpeed;
        if (vNext < 0) {
            vNext = 0;
        }
        _velocity *= vNext / vCurrent;
    }
}

- (NSArray*) viewControllers
{
    AP_PageView* view = (AP_PageView*) self.view;
    if (view.spineLocation == UIPageViewControllerSpineLocationMid) {
        // Two pages visible
        if (view.position < 0) {
            return [NSArray arrayWithObjects:
                view.midPage.viewDelegate,
                view.rightPage.viewDelegate,
                nil];
        } else {
            return [NSArray arrayWithObjects:
                view.leftPage.viewDelegate,
                view.midPage.viewDelegate,
                nil];
        }
    } else {
        // Only the right-hand page is visible
        if (view.position < 0) {
            return [NSArray arrayWithObjects:
                view.rightPage.viewDelegate,
                nil];
        } else {
            return [NSArray arrayWithObjects:
                view.midPage.viewDelegate,
                nil];
        }
    }
}

- (void) setViewControllers:(NSArray*)viewControllers direction:(UIPageViewControllerNavigationDirection)direction animated:(BOOL)animated completion:(void (^)(BOOL))completion
{
    // Ignore animated / completion

    AP_ViewController* mid = [viewControllers lastObject];
    AP_ViewController* right = [_dataSource pageViewController:self viewControllerAfterViewController:mid];
    AP_ViewController* left = [_dataSource pageViewController:self viewControllerBeforeViewController:mid];

    AP_PageView* view = (AP_PageView*) self.view;
    [view setLeft:left.view mid:mid.view right:right.view];
}

@end
