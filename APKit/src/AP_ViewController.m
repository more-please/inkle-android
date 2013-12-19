#import "AP_ViewController.h"

#import "AP_Check.h"
#import "NSObject+AP_KeepAlive.h"

@implementation AP_ViewController {
    AP_View* _view;
    AP_ViewController* _parent;
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

- (void) dealloc
{
    NSLog(@"Deleting AP_ViewController: %@", self);
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
    self.view = [[AP_View alloc] init];
}

- (void) addChildViewController:(AP_ViewController*)child
{
    AP_CHECK(child, return);

    [child willMoveToParentViewController:self];

    if (child->_parent) {
        [child->_parent->_childViewControllers removeObject:child];
    }
    [_childViewControllers addObject:child];
    child->_parent = self;

    [child didMoveToParentViewController:self];
}

- (void) removeFromParentViewController
{
    if (_parent) {
        [self willMoveToParentViewController:self];
        [_parent->_childViewControllers removeObject:self];
        _parent = nil;
        [self didMoveToParentViewController:nil];
    }
}

- (void) willMoveToParentViewController:(AP_ViewController*)parent {}
- (void) didMoveToParentViewController:(AP_ViewController*)parent {}

- (void) didReceiveMemoryWarning {}
- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {}
- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {}

- (AP_Responder*) nextResponder
{
    if (_view.superview) {
        return _view.superview;
    }
    if (_parent) {
        return _parent;
    }
    return nil;
}

@end
