#import "AP_GLKView.h"

#import "AP_Check.h"

@implementation AP_GLKView

- (void) updateGL
{
    [super updateGL];

    AP_CHECK(_delegate, return);
    [_delegate update];
}

- (void) renderWithBoundsToGL:(CGAffineTransform)boundsToGL alpha:(CGFloat)alpha
{
    [super renderWithBoundsToGL:boundsToGL alpha:alpha];

    AP_CHECK(_delegate, return);
    [_delegate glkView:self drawInRect:self.bounds];
}

@end
