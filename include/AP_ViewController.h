#import <Foundation/Foundation.h>

#ifdef AP_REPLACE_UI

#import "AP_View.h"

@interface AP_ViewController : NSObject

@property(nonatomic, retain) AP_View *view;

- (BOOL) isViewLoaded;

- (void) viewDidLoad;

- (void) viewWillAppear:(BOOL)animated;
- (void) viewDidAppear:(BOOL)animated;
- (void) viewWillDisappear:(BOOL)animated;
- (void) viewDidDisappear:(BOOL)animated;

- (void) addChildViewController:(AP_ViewController *)childController;
- (void) removeFromParentViewController;
- (void) willMoveToParentViewController:(AP_ViewController*)parent;
- (void) didMoveToParentViewController:(AP_ViewController*)parent;

- (void) viewWillLayoutSubviews;
- (void) viewDidLayoutSubviews;

- (void) presentModalViewController:(AP_ViewController*)modalViewController animated:(BOOL)animated;
- (void) dismissModalViewControllerAnimated:(BOOL)animated;

@property(nonatomic,readonly) UIInterfaceOrientation interfaceOrientation;
@property(nonatomic,readonly) NSArray* childViewControllers;

// These methods are delegated from the real UIViewController.

- (void) didReceiveMemoryWarning;
- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;

@end

#else
typedef UIViewController AP_ViewController;
#endif
