#import "AP_GLKView.h"

#import <OpenGLES/ES2/gl.h>

#import "AP_Check.h"

@implementation AP_GLKView

- (void) updateGL:(float)dt
{
    [super updateGL:dt];

    AP_CHECK(_delegate, return);
    [_delegate update];
}

- (void) renderWithBoundsToGL:(CGAffineTransform)boundsToGL alpha:(CGFloat)alpha
{
    [super renderWithBoundsToGL:boundsToGL alpha:alpha];

    // Bit of a hack here... adjust the GL viewport to compensate for our view frame.
    // It would be better to adjust the projection matrix, but that would require
    // changes to SceneController (plus, getting those matrices right is hard!)

    UIScreen* screen = [UIScreen mainScreen];
    float scale = screen.scale;
    CGRect bounds = screen.bounds;

    CGRect frame = [self convertInFlightRect:self.inFlightBounds toView:nil];
    CGPoint offset = {
        frame.origin.x - bounds.origin.x,
        frame.origin.y - bounds.origin.y,
    };

    _GL(Viewport, 
        offset.x * scale,
        -offset.y * scale, // GL origin is at the bottom-left
        bounds.size.width * scale,
        bounds.size.height * scale);

    // Draw!
    AP_CHECK(_delegate, return);
    [_delegate glkView:self drawWithAlpha:alpha];

    // Restore the normal viewport.
    _GL(Viewport, 0, 0, bounds.size.width * scale, bounds.size.height * scale);
}

@end
