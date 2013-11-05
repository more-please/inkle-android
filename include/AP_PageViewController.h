#import <Foundation/Foundation.h>

#import "AP_ViewController.h"

#ifdef AP_REPLACE_UI

@class AP_PageViewController;

@protocol AP_PageViewControllerDelegate <NSObject>
@end

@protocol AP_PageViewControllerDataSource <NSObject>

@required
- (AP_PageViewController*) pageViewController:(AP_PageViewController*)pageViewController viewControllerBeforeViewController:(AP_ViewController*)viewController;
- (AP_PageViewController*) pageViewController:(AP_PageViewController*)pageViewController viewControllerAfterViewController:(AP_ViewController*)viewController;
@end

#ifdef ANDROID
typedef NS_ENUM(NSInteger, UIPageViewControllerNavigationOrientation) {
    UIPageViewControllerNavigationOrientationHorizontal = 0,
    UIPageViewControllerNavigationOrientationVertical = 1
};
typedef NS_ENUM(NSInteger, UIPageViewControllerSpineLocation) {
    UIPageViewControllerSpineLocationNone = 0,
    UIPageViewControllerSpineLocationMin = 1,
    UIPageViewControllerSpineLocationMid = 2,
    UIPageViewControllerSpineLocationMax = 3
};
typedef NS_ENUM(NSInteger, UIPageViewControllerNavigationDirection) {
    UIPageViewControllerNavigationDirectionForward,
    UIPageViewControllerNavigationDirectionReverse
};
typedef NS_ENUM(NSInteger, UIPageViewControllerTransitionStyle) {
    UIPageViewControllerTransitionStylePageCurl = 0,
    UIPageViewControllerTransitionStyleScroll = 1
};
#endif // ANDROID

@interface AP_PageViewController : AP_ViewController

@property (assign) id<AP_PageViewControllerDataSource> dataSource;
@property (assign) id<AP_PageViewControllerDelegate> delegate;
@property (readonly) NSArray *viewControllers;
@property (getter=isDoubleSided) BOOL doubleSided; // Default is 'NO'.
@property (readonly) UIPageViewControllerSpineLocation spineLocation;

- (id)initWithTransitionStyle:(UIPageViewControllerTransitionStyle)style navigationOrientation:(UIPageViewControllerNavigationOrientation)navigationOrientation options:(NSDictionary *)options;
- (void)setViewControllers:(NSArray *)viewControllers direction:(UIPageViewControllerNavigationDirection)direction animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

@end

#else
typedef UIPageViewController AP_PageViewController;
#define AP_PageViewControllerDelegate UIPageViewControllerDelegate
#define AP_PageViewControllerDataSource UIPageViewControllerDataSource
#endif
