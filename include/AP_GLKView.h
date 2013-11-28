#import <GLKit/GLKit.h>

#import "AP_ViewController.h"

#ifdef AP_REPLACE_UI

@class AP_GLKView;

@protocol AP_GLKViewDelegate <NSObject>
@required
- (void)update;
- (void)glkView:(AP_GLKView *)view drawInRect:(CGRect)rect;
@end

@interface AP_GLKView : AP_View

@property id <AP_GLKViewDelegate> delegate;

@end

#else
typedef GLKView AP_GLKView;
#endif
