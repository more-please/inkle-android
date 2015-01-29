#import "AP_GLKViewController.h"

#import "AP_Check.h"
#import "AP_Window.h"

@implementation AP_GLKViewController

- (void) loadView
{
    self.view = [[AP_GLKView alloc] initWithFrame:[AP_Window screenBounds]];
}

- (void) update
{
    // Nothing
}

- (void) glkView:(AP_GLKView *)view drawWithAlpha:(CGFloat)alpha
{
    [self glkView:view drawInRect:view.bounds];
}

- (void) glkView:(AP_GLKView *)view drawInRect:(CGRect)rect
{
    // Nothing
}

@end
