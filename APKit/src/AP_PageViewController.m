#import "AP_PageViewController.h"

#import "AP_Check.h"

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
            CGRect r = pageRect;
            r.size = [page sizeThatFits:r.size];
            page.frame = r;
            pageRect.origin.x += r.size.width;
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
    }
    return self;
}

- (void) loadView
{
    self.view = [[AP_PageView alloc] init];
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
