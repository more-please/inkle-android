#import <GLKit/GLKit.h>

#import "AP_ViewController.h"

#ifdef AP_REPLACE_UI

@interface AP_GLKViewController : AP_ViewController

@end

#else
typedef GLKViewController AP_GLKViewController;
#endif
