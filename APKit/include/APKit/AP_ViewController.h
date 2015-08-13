#pragma once

#import <Foundation/Foundation.h>

#import "AP_Responder.h"
#import "AP_View.h"

@interface AP_ViewController : AP_Responder

@property(nonatomic, strong) AP_View *view;

- (BOOL) isViewLoaded;

- (void) loadView;
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

@property(nonatomic,readonly) UIInterfaceOrientation interfaceOrientation;
@property(nonatomic,readonly,strong) NSArray* childViewControllers;
@property(nonatomic,readonly,weak) AP_ViewController* parentViewController;

@property(nonatomic,copy) NSString *title;  // Localized title for use by a parent controller.

@property(nonatomic,readonly) float timeSinceLastUpdate;

// Android-specific additions
- (BOOL) handleAndroidBackButton; // Return YES if the event was handled.

// These methods are delegated from the real UIViewController.

- (void) didReceiveMemoryWarning;
- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;

- (void) updateGL:(float)dt;

@end
