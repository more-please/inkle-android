#import "AP_PageViewController.h"

#import "AP_Check.h"
#import "AP_Window.h"

@interface AP_PageView : AP_View
@end

@implementation AP_PageView
- (void) layoutSubviews
{
    NSArray* pages = self.subviews;
    if (pages.count > 0) {
        // Fill our frame by tiling the views horizontally.
        CGRect pageRect = self.bounds;
        pageRect.size.width /= pages.count;
        for (AP_View* page in pages) {
            page.frame = pageRect;
            pageRect.origin.x += pageRect.size.width;
        }
    }
}
@end

@implementation AP_PageViewController {
    NSMutableArray* _viewControllers;
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
        _viewControllers = [NSMutableArray array];

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
}

- (void) loadView
{
    AP_View* view = [[AP_PageView alloc] init];
    AP_TapGestureRecognizer* gesture = [[AP_TapGestureRecognizer alloc] initWithTarget:self action:@selector(pageTappedWithRecognizer:)];
    [view addGestureRecognizer:gesture];

    self.view = view;
}

- (void) pageTappedWithRecognizer:(AP_GestureRecognizer*)tap
{
    NSMutableArray* newPages = [_viewControllers mutableCopy];

    AP_View* view = self.view;
    CGPoint pos = [tap locationInView:view];
    if (pos.x > view.bounds.size.width / 2) {
        // Go to the next page(s)
        AP_PageViewController* lastPage = [_viewControllers lastObject];
        for (int i = 0; i < _viewControllers.count; i++) {
            AP_PageViewController* newPage = [_dataSource pageViewController:self viewControllerAfterViewController:lastPage];
            if (!newPage) {
                break;
            }
            [newPages addObject:newPage];
            [newPages removeObjectAtIndex:0];
            lastPage = newPage;
        }
    } else {
        // Go to the previous page(s)
        AP_PageViewController* firstPage = [_viewControllers objectAtIndex:0];
        for (int i = 0; i < _viewControllers.count; i++) {
            AP_PageViewController* newPage = [_dataSource pageViewController:self viewControllerBeforeViewController:firstPage];
            if (!newPage) {
                break;
            }
            [newPages insertObject:newPage atIndex:0];
            [newPages removeLastObject];
            firstPage = newPage;
        }
    }

    [self setViewControllers:newPages direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (NSArray*) viewControllers
{
    return _viewControllers;
}

- (void) setViewControllers:(NSArray*)viewControllers direction:(UIPageViewControllerNavigationDirection)direction animated:(BOOL)animated completion:(void (^)(BOOL))completion
{
    // Ignore animated / completion

    // Remove current view controllers
    for (AP_ViewController* vc in _viewControllers) {
        if (vc.isViewLoaded) {
            [vc.view removeFromSuperview];
        }
        [vc removeFromParentViewController];
    }

    // Add new ones
    _viewControllers = [viewControllers mutableCopy];
    for (AP_ViewController* vc in _viewControllers) {
        [self addChildViewController:vc];
        [self.view addSubview:vc.view];
    }
}

@end
