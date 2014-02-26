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
    mid.origin.x = AP_Lerp(left.origin.x, right.origin.x, (_position + 1) / 2);
    
    _leftPage.frame = left;
    _midPage.frame = mid;
    _rightPage.frame = right;
}
@end

@implementation AP_PageViewController {
    CGFloat _positionBeforeGesture;
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
    AP_PageView* view = (AP_PageView*) self.view;
    UIGestureRecognizerState state = pan.state;

    if (state == UIGestureRecognizerStateBegan) {
        _positionBeforeGesture = view.position;
    }
    
    if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged) {
        CGFloat delta = [pan translationInView:view].x / view.bounds.size.width;
        if (_spineLocation == UIPageViewControllerSpineLocationMid) {
            delta *= 2;
        }

        view.position = _positionBeforeGesture + delta;
        if (view.position < -1) {
            AP_PageViewController* newPage = [_dataSource pageViewController:self viewControllerAfterViewController:view.rightPage.viewDelegate];
            if (newPage) {
                [view addOnRight:newPage.view];
                _positionBeforeGesture += 2;
            } else {
                view.position = -1;
            }
        } else if (view.position > 1) {
            AP_PageViewController* newPage = [_dataSource pageViewController:self viewControllerBeforeViewController:view.leftPage.viewDelegate];
            if (newPage) {
                [view addOnLeft:newPage.view];
                _positionBeforeGesture -= 2;
            } else {
                view.position = 1;
            }
        }
    }
}

- (NSArray*) viewControllers
{
    AP_PageView* view = (AP_PageView*) self.view;
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
