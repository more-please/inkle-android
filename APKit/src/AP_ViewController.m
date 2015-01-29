#import "AP_ViewController.h"

#import "AP_Check.h"
#import "NSObject+AP_KeepAlive.h"

@implementation AP_ViewController {
    AP_View* _view;
    NSMutableArray* _childViewControllers;
}

- (id) init
{
    self = [super init];
    if (self) {
        _childViewControllers = [NSMutableArray array];
    }
    return self;
}

- (BOOL) goBack
{
    return [self.view goBack];
}

- (AP_View*) view
{
    if (!_view) {
        [self loadView];
        AP_CHECK(_view, return nil);
        [self viewDidLoad];
    }
    return _view;
}

- (void) setView:(AP_View *)view
{
    _view = view;
    _view.viewDelegate = self;
}

- (BOOL) isViewLoaded
{
    return (_view != nil);
}

- (void) viewDidLoad {}
- (void) viewWillAppear:(BOOL)animated {}
- (void) viewDidAppear:(BOOL)animated {}
- (void) viewWillDisappear:(BOOL)animated {}
- (void) viewDidDisappear:(BOOL)animated {}

- (void) viewWillLayoutSubviews {}
- (void) viewDidLayoutSubviews {}

- (void) loadView
{
    self.view = [[AP_View alloc] initWithFrame:[UIScreen mainScreen].bounds];
}

- (void) protectAgainstIteration
{
    _childViewControllers = [_childViewControllers mutableCopy];
}

- (void) addChildViewController:(AP_ViewController*)child
{
    AP_CHECK(child, return);

    [child willMoveToParentViewController:self];

    AP_ViewController* p = child->_parentViewController;
    if (p) {
        [p protectAgainstIteration];
        [p->_childViewControllers removeObject:child];
    }
    [self protectAgainstIteration];
    [_childViewControllers addObject:child];
    child->_parentViewController = self;

    [child didMoveToParentViewController:self];
}

- (void) removeFromParentViewController
{
    id protectSelf = self;
    AP_ViewController* p = _parentViewController;
    if (p) {
        [self willMoveToParentViewController:self];
        [p protectAgainstIteration];
        [p->_childViewControllers removeObject:self];
        _parentViewController = nil;
        [self didMoveToParentViewController:nil];
    }
    [protectSelf self];
}

- (void) willMoveToParentViewController:(AP_ViewController*)parent {}
- (void) didMoveToParentViewController:(AP_ViewController*)parent {}

- (void) didReceiveMemoryWarning {}
- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {}
- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {}

- (AP_Responder*) nextResponder
{
    AP_View* superview = _view.superview;
    if (superview) {
        return superview;
    }
    AP_ViewController* p = _parentViewController;
    if (p) {
        return p;
    }
    return nil;
}

- (UIInterfaceOrientation) interfaceOrientation
{
    CGSize s = [UIScreen mainScreen].bounds.size;
    return (s.width > s.height)
        ? UIInterfaceOrientationLandscapeLeft
        : UIInterfaceOrientationPortrait;
}

- (void) updateGL:(float)dt
{
    _timeSinceLastUpdate = dt;
}

@end
