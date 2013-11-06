#import <Foundation/Foundation.h>

#ifdef AP_REPLACE_UI

#import "AP_View.h"

@interface AP_ViewController : NSObject

@property(nonatomic, retain) AP_View *view;

- (BOOL) isViewLoaded;

- (void) viewDidAppear:(BOOL)animated;
- (void) viewDidLoad;
- (void) viewWillDisappear:(BOOL)animated;
- (void) viewDidDisappear:(BOOL)animated;

- (void) didReceiveMemoryWarning;

- (void) addChildViewController:(AP_ViewController *)childController;
- (void) removeFromParentViewController;
- (void) willMoveToParentViewController:(AP_ViewController*)parent;
- (void) didMoveToParentViewController:(AP_ViewController*)parent;

- (void) viewWillLayoutSubviews;
- (void) viewDidLayoutSubviews;

- (void) presentModalViewController:(AP_ViewController*)modalViewController animated:(BOOL)animated;
- (void) dismissModalViewControllerAnimated:(BOOL)animated;

@property(readonly) UIInterfaceOrientation interfaceOrientation;
@property(readonly) NSArray* childViewControllers;

@end

#else
typedef UIViewController AP_ViewController;
#endif
