#import "AP_ImageView.h"

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
        AP_AnimationProps* props = self.inFlightProps;
        CGRect bounds = props.bounds;
        CGPoint pos = CGPointMake(bounds.origin.x + bounds.size.width/2, bounds.origin.y + bounds.size.height/2);
        CGSize size = _image.size;
        
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
            case UIViewContentModeBottom:
            case UIViewContentModeLeft:
            case UIViewContentModeRight:
            case UIViewContentModeTopLeft:
            case UIViewContentModeTopRight:
            case UIViewContentModeBottomLeft:
            case UIViewContentModeBottomRight:
            case UIViewContentModeRedraw:
            default:
                AP_LogError("Content mode %d not implemented", self.contentMode);
                return;
        }

        // The image will be rendered around 0,0, at its natural size.
        // To transform it into GL coordinates, we need to do the following:
        // - scale to the correct size
        // - translate it into bounds coordinates
        // - apply boundsToGL.
        
        CGAffineTransform t = CGAffineTransformScale(
                CGAffineTransformTranslate(
                    boundsToGL,
                    pos.x, pos.y),
            size.width / _image.pixelSize.width,
            size.height / _image.pixelSize.height);

//        NSLog(@"Rendering %@, pos: %.0f,%.0f size: %.0f,%.0f alpha: %.2f", _image.assetName, pos.x, pos.y, size.width, size.height, alpha);
        [_image renderGLWithTransform:t alpha:alpha];
    }
}

@end