#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#import "AP_ViewController.h"

#ifdef AP_REPLACE_UI

// Plays the role of a UIWindow containing UIViews.
// Actually implemented as a GL-based UIView.

@interface AP_Window : GLKViewController

@property (readonly) CGRect bounds;

@property AP_ViewController* rootViewController;

+ (CGSize) realScreenSize;

@end

#else
typedef UIWindow AP_Window;
#endif
