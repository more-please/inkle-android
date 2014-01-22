#import "AP_Button.h"

#import "AP_Check.h"

@implementation AP_Button {
    NSMutableDictionary* _title;
    NSMutableDictionary* _titleColor;
    NSMutableDictionary* _titleShadowColor;
    NSMutableDictionary* _image;
    NSMutableDictionary* _backgroundImage;
    BOOL _needsStateRefresh;
}

+ (AP_Button*) buttonWithType:(UIButtonType)buttonType
{
    AP_CHECK(buttonType == UIButtonTypeCustom, return nil);
    return [[AP_Button alloc] init];
}

- (void) commonButtonInit
{
    _titleLabel = [[AP_Label alloc] initWithFrame:self.bounds];
    _titleLabel.autoresizingMask = -1;
    _titleLabel.textAlignment = NSTextAlignmentCenter;

    _imageView = [[AP_ImageView alloc] initWithFrame:self.bounds];
    _imageView.autoresizingMask = -1;
    _imageView.contentMode = UIViewContentModeScaleToFill;

    _titleEdgeInsets = UIEdgeInsetsZero;
    _imageEdgeInsets = UIEdgeInsetsZero;

    [self addSubview:_titleLabel];
    [self addSubview:_imageView];

    _title = [NSMutableDictionary dictionary];
    _titleColor = [NSMutableDictionary dictionary];
    _titleShadowColor = [NSMutableDictionary dictionary];
    _image = [NSMutableDictionary dictionary];
    _backgroundImage = [NSMutableDictionary dictionary];
}

- (id) init
{
    self = [super init];
    if (self) {
        [self commonButtonInit];
    }
    return self;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonButtonInit];
    }
    return self;
}

- (void) layoutSubviews
{
    [self refreshStateIfNeeded];

    // The behaviour of the insets is a bit weird. As far as I can figure out,
    // the image insets are applied to the button bounds, and the image is laid
    // out within those bounds as if the label were present; then the label insets
    // are applied and the label is laid out as if the image were present.

    CGRect bounds = self.bounds;
    CGRect boundsForImage = UIEdgeInsetsInsetRect(bounds, _imageEdgeInsets);
    CGRect boundsForLabel = UIEdgeInsetsInsetRect(bounds, _titleEdgeInsets);

    CGRect imageFrame, labelFrame, unusedFrame;
    [self layoutWithBounds:boundsForImage imageFrame:&imageFrame labelFrame:&unusedFrame];
    [self layoutWithBounds:boundsForLabel imageFrame:&unusedFrame labelFrame:&labelFrame];

    _imageView.frame = imageFrame;
    _titleLabel.frame = labelFrame;
}

- (void) layoutWithBounds:(CGRect)bounds imageFrame:(CGRect*)imageFrame labelFrame:(CGRect*)labelFrame
{
    *imageFrame = CGRectZero;
    *labelFrame = CGRectZero;

    // Both image and text have their natural size.
    if ([self imageForState:UIControlStateNormal]) {
        imageFrame->size = [self imageForState:UIControlStateNormal].size;
    }
    labelFrame->size = [_titleLabel sizeThatFits:CGSizeMake(2000.0, 2000.0)];

    // The horizontal positioning depends on the button width.
    if (bounds.size.width > imageFrame->size.width + labelFrame->size.width) {
        // The button is wide: image on the left, text on the right, everything centered.
        imageFrame->origin.x = bounds.origin.x + 0.5 * (bounds.size.width - (imageFrame->size.width + labelFrame->size.width));
    } else if (bounds.size.width > imageFrame->size.width) {
        // The button is wide enough for the image, but not the text.
        // Left-align the image and fit in as much of the text as we can.
        imageFrame->origin.x = bounds.origin.x;
    } else {
        // The button isn't wide enough for the image.
        // iOS shrinks it, but I think it looks better if we center it.
        imageFrame->origin.x = bounds.origin.x + 0.5 * (bounds.size.width - imageFrame->size.width);
    }

    // The label is always immediately to the right of the image.
    labelFrame->origin.x = imageFrame->origin.x + imageFrame->size.width;

    // Both image and text are centered vertically.
    imageFrame->origin.y = bounds.origin.y + 0.5 * (bounds.size.height - imageFrame->size.height);
    labelFrame->origin.y = bounds.origin.y + 0.5 * (bounds.size.height - labelFrame->size.height);
}

- (void) setNeedsLayout
{
    _needsStateRefresh = YES;
    [super setNeedsLayout];
}

- (void) setTitle:(NSString*)title forState:(UIControlState)state
{
    [_title setObject:title forKey:[NSNumber numberWithInt:state]];
    [self setNeedsLayout];
}

- (void) setTitleColor:(UIColor*)color forState:(UIControlState)state
{
    [_titleColor setObject:color forKey:[NSNumber numberWithInt:state]];
    _needsStateRefresh = YES;
}

- (void) setTitleShadowColor:(UIColor*)color forState:(UIControlState)state
{
    [_titleShadowColor setObject:color forKey:[NSNumber numberWithInt:state]];
    _needsStateRefresh = YES;
}

- (void) setImage:(AP_Image*)image forState:(UIControlState)state
{
    [_image setObject:image forKey:[NSNumber numberWithInt:state]];
    [self setNeedsLayout];
}

- (void) setBackgroundImage:(AP_Image*)image forState:(UIControlState)state
{
    [_backgroundImage setObject:image forKey:[NSNumber numberWithInt:state]];
    _needsStateRefresh = YES;
}

- (NSString*)titleForState:(UIControlState)state
{
    NSString* result = [_title objectForKey:[NSNumber numberWithInt:state]];
    if (!result) {
        result = [_title objectForKey:[NSNumber numberWithInt:UIControlStateNormal]];
    }
    return result;
}

- (UIColor*)titleColorForState:(UIControlState)state
{
    UIColor* result = [_titleColor objectForKey:[NSNumber numberWithInt:state]];
    if (!result) {
        result = [_titleColor objectForKey:[NSNumber numberWithInt:UIControlStateNormal]];
    }
    if (!result) {
        result = [UIColor whiteColor];
    }
    return result;
}

- (UIColor*)titleShadowColorForState:(UIControlState)state
{
    UIColor* result = [_titleShadowColor objectForKey:[NSNumber numberWithInt:state]];
    if (!result) {
        result = [_titleShadowColor objectForKey:[NSNumber numberWithInt:UIControlStateNormal]];
    }
    if (!result) {
        result = [UIColor colorWithWhite:0 alpha:0.5];
    }
    return result;
}

- (AP_Image*)imageForState:(UIControlState)state
{
    AP_Image* result = [_image objectForKey:[NSNumber numberWithInt:state]];
    if (!result) {
        result = [_image objectForKey:[NSNumber numberWithInt:UIControlStateNormal]];
    }
    return result;
}

- (AP_Image*)backgroundImageForState:(UIControlState)state
{
    AP_Image* result = [_backgroundImage objectForKey:[NSNumber numberWithInt:state]];
    if (!result) {
        result = [_backgroundImage objectForKey:[NSNumber numberWithInt:UIControlStateNormal]];
    }
    return result;
}

- (void) setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self setNeedsLayout];
}

- (void) refreshStateIfNeeded
{
    if (_needsStateRefresh) {
        UIControlState state = self.highlighted ? UIControlStateHighlighted : UIControlStateNormal;

        [_titleLabel setText:[self titleForState:state]];
        [_titleLabel setTextColor:[self titleColorForState:state]];
        [_titleLabel setShadowColor: [self titleShadowColorForState:state]];
        [_imageView setImage:[self imageForState:state]];

        _needsStateRefresh = NO;
    }
}

- (void) updateGL
{
    [self refreshStateIfNeeded];
}

- (void) renderSelfAndChildrenWithFrameToGL:(CGAffineTransform)frameToGL alpha:(CGFloat)alpha
{
    [super renderSelfAndChildrenWithFrameToGL:frameToGL alpha:alpha];
}

- (void) renderWithBoundsToGL:(CGAffineTransform)boundsToGL alpha:(CGFloat)alpha
{
    UIControlState state = self.highlighted ? UIControlStateHighlighted : UIControlStateNormal;
    AP_Image* image = [self backgroundImageForState:state];
    if (image) {
        CGRect bounds = self.inFlightBounds;
        CGPoint pos = CGPointMake(bounds.origin.x + bounds.size.width/2, bounds.origin.y + bounds.size.height/2);
        CGSize size = bounds.size;

        CGAffineTransform t = CGAffineTransformScale(
                CGAffineTransformTranslate(
                    boundsToGL,
                    pos.x, pos.y),
            size.width / image.pixelSize.width,
            size.height / image.pixelSize.height);

        [image renderGLWithTransform:t alpha:alpha];
    }
}

@end
