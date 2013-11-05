#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#import "AP_View.h"

#ifdef AP_REPLACE_UI

// Plays the role of a UIWindow containing UIViews.
// Actually implemented as a GL-based UIView.

@interface AP_Window : GLKViewController

@property (readonly) CGRect bounds;

@property AP_View* rootView;

@end

#else
typedef UIWindow AP_Window;
#endif
