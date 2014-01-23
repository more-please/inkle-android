#import "AP_ImageView.h"

#import <OpenGLES/ES2/gl.h>

#import "AP_Log.h"

@implementation AP_ImageView

- (AP_ImageView*) initWithImage:(AP_Image *)image
{
    self = [super initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    if (self) {
        _image = image;
    }
    return self;
}

- (CGSize) sizeThatFits:(CGSize)size
{
    return _image.size;
}

- (void) renderWithBoundsToGL:(CGAffineTransform)boundsToGL alpha:(CGFloat)alpha
{
    [super renderWithBoundsToGL:boundsToGL alpha:alpha];

    if (alpha <= 0) {
        return;
    }
    if (alpha > 1) {
        alpha = 1;
    }
    if (_image) {
        CGRect bounds = self.inFlightBounds;

        CGPoint center = CGPointMake(bounds.origin.x + bounds.size.width/2, bounds.origin.y + bounds.size.height/2);
        CGSize size = _image.size;

        CGFloat xGap = (size.width - bounds.size.width) / 2;
        CGFloat yGap = (size.height - bounds.size.height) / 2;

        switch (self.contentMode) {
            case UIViewContentModeScaleToFill:
                size = bounds.size;
                break;

            case UIViewContentModeScaleAspectFit: {
                CGSize mySize = bounds.size;
                CGFloat xScale = mySize.width / size.width;
                CGFloat yScale = mySize.height / size.height;
                CGFloat minScale = MIN(xScale, yScale);
                size.width *= minScale;
                size.height *= minScale;
            }
                break;

            case UIViewContentModeScaleAspectFill: {
                CGSize mySize = bounds.size;
                CGFloat xScale = mySize.width / size.width;
                CGFloat yScale = mySize.height / size.height;
                CGFloat maxScale = MAX(xScale, yScale);
                size.width *= maxScale;
                size.height *= maxScale;
            }
                break;

            case UIViewContentModeCenter:
                break;

            case UIViewContentModeTop:
                center.y -= yGap;
                break;

            case UIViewContentModeBottom:
                center.y += yGap;
                break;

            case UIViewContentModeLeft:
                center.x -= xGap;
                break;

            case UIViewContentModeRight:
                center.x += xGap;
                break;

            case UIViewContentModeTopLeft:
                center.x -= xGap;
                center.y -= yGap;
                break;

            case UIViewContentModeTopRight:
                center.x += xGap;
                center.y -= yGap;
                break;

            case UIViewContentModeBottomLeft:
                center.x -= xGap;
                center.y += yGap;
                break;

            case UIViewContentModeBottomRight:
                center.x += xGap;
                center.y += yGap;
                break;

            case UIViewContentModeRedraw:
            default:
                AP_LogError("Content mode %d not implemented", self.contentMode);
                return;
        }

        // The image will be rendered with its top-left corner at 0,0.
        // To transform it into GL coordinates, we need to translate it
        // into bounds coordinates, then apply boundsToGL.
        
        CGAffineTransform t = CGAffineTransformTranslate(
            boundsToGL,
            center.x - size.width/2,
            center.y - size.height/2);

//        NSLog(@"Rendering %@, pos: %.0f,%.0f size: %.0f,%.0f alpha: %.2f", _image.assetName, pos.x, pos.y, size.width, size.height, alpha);

        if (self.clipsToBounds) {
            CGRect r = [self convertInFlightRect:bounds toView:nil];
            UIScreen* screen = [UIScreen mainScreen];
            CGFloat scale = screen.scale;
            int x = r.origin.x * scale;
            int y = (screen.bounds.size.height - (r.origin.y + r.size.height)) * scale;
            int w = r.size.width * scale;
            int h = r.size.height * scale;
            glEnable(GL_SCISSOR_TEST);
            glScissor(x, y, w, h);
        }

        [_image renderGLWithSize:size transform:t alpha:alpha];

        if (self.clipsToBounds) {
            glDisable(GL_SCISSOR_TEST);
        }
    }
}

@end
