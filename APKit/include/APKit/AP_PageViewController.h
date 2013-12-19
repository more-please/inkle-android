#pragma once

#import <Foundation/Foundation.h>

#import "AP_ViewController.h"

@class AP_PageViewController;

@protocol AP_PageViewControllerDelegate <NSObject>
@end

@protocol AP_PageViewControllerDataSource <NSObject>

@required
- (AP_PageViewController*) pageViewController:(AP_PageViewController*)pageViewController viewControllerBeforeViewController:(AP_ViewController*)viewController;
- (AP_PageViewController*) pageViewController:(AP_PageViewController*)pageViewController viewControllerAfterViewController:(AP_ViewController*)viewController;
@end

@interface AP_PageViewController : AP_ViewController

@property (weak) id<AP_PageViewControllerDataSource> dataSource;
@property (weak) id<AP_PageViewControllerDelegate> delegate;
@property (readonly) NSArray *viewControllers;
@property (getter=isDoubleSided) BOOL doubleSided; // Default is 'NO'.
@property (readonly) UIPageViewControllerSpineLocation spineLocation;

- (id)initWithTransitionStyle:(UIPageViewControllerTransitionStyle)style navigationOrientation:(UIPageViewControllerNavigationOrientation)navigationOrientation options:(NSDictionary *)options;
- (void)setViewControllers:(NSArray *)viewControllers direction:(UIPageViewControllerNavigationDirection)direction animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

@end
