#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <GLKit/GLKit.h>

#import "AP_ViewController.h"

#ifdef AP_REPLACE_UI

// Plays the role of a UIWindow containing UIViews.
// Actually implemented as a GL-based UIView.

@interface AP_Window : GLKViewController

@property (readonly) CGRect bounds;

@property AP_ViewController* rootViewController;

+ (CGRect) screenBounds;
+ (CGSize) screenSize;
+ (CGFloat) screenScale;

// Get a metric scaled to fit the current device, such that it has
// the specified values on a Retina iPhone (3.5") or iPad. We'll
// interpolate between the given values for other screen sizes.
// (For non-Retina devices, the value will be divided by 2.)
+ (CGFloat) iPhone:(CGFloat)iPhone iPad:(CGFloat)iPad;

@end

#else
typedef UIWindow AP_Window;
#endif
