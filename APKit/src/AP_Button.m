#import "AP_Button.h"

#import "AP_Check.h"

@implementation AP_Button {
    NSMutableDictionary* _title;
    NSMutableDictionary* _titleColor;
    NSMutableDictionary* _titleShadowColor;
    NSMutableDictionary* _image;
    NSMutableDictionary* _backgroundImage;
    NSMutableDictionary* _backgroundColor;
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
    _showsTouchWhenHighlighted = NO;
    _adjustsImageWhenHighlighted = YES;

    [self addSubview:_titleLabel];
    [self addSubview:_imageView];

    _title = [NSMutableDictionary dictionary];
    _titleColor = [NSMutableDictionary dictionary];
    _titleShadowColor = [NSMutableDictionary dictionary];
    _image = [NSMutableDictionary dictionary];
    _backgroundImage = [NSMutableDictionary dictionary];
    _backgroundColor = [NSMutableDictionary dictionary];
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
    id key = [NSNumber numberWithInt:state];
    if (title) {
        [_title setObject:title forKey:key];
    } else {
        [_title removeObjectForKey:key];
    }
    [self setNeedsLayout];
}

- (void) setTitleColor:(UIColor*)color forState:(UIControlState)state
{
    id key = [NSNumber numberWithInt:state];
    if (color) {
        [_titleColor setObject:color forKey:key];
    } else {
        [_titleColor removeObjectForKey:key];
    }
    _needsStateRefresh = YES;
}

- (void) setTitleShadowColor:(UIColor*)color forState:(UIControlState)state
{
    id key = [NSNumber numberWithInt:state];
    if (color) {
        [_titleShadowColor setObject:color forKey:key];
    } else {
        [_titleShadowColor removeObjectForKey:key];
    }
    _needsStateRefresh = YES;
}

- (void) setImage:(AP_Image*)image forState:(UIControlState)state
{
    id key = [NSNumber numberWithInt:state];
    if (image) {
        [_image setObject:image forKey:key];
    } else {
        [_image removeObjectForKey:key];
    }
    [self setNeedsLayout];
}

- (void) setBackgroundImage:(AP_Image*)image forState:(UIControlState)state
{
    id key = [NSNumber numberWithInt:state];
    if (image) {
        [_backgroundImage setObject:image forKey:key];
    } else {
        [_backgroundImage removeObjectForKey:key];
    }
    _needsStateRefresh = YES;
}

- (void) setBackgroundColor:(UIColor*)color forState:(UIControlState)state
{
    id key = [NSNumber numberWithInt:state];
    if (color) {
        [_backgroundColor setObject:color forKey:key];
    } else {
        [_backgroundColor removeObjectForKey:key];
    }
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

- (UIColor*)backgroundColorForState:(UIControlState)state
{
    UIColor* result = [_backgroundColor objectForKey:[NSNumber numberWithInt:state]];
    if (!result) {
        result = [_backgroundColor objectForKey:[NSNumber numberWithInt:UIControlStateNormal]];
    }
    if (!result) {
        result = [UIColor colorWithWhite:0 alpha:0];
    }
    return result;
}

- (AP_Image*) maybeAdjustImage:(AP_Image*)image forState:(UIControlState)state
{
    // Apple docs don't explain the exact semantics of adjustsImageWhenHighlighted, sigh.
    // I'm assuming that:
    // - Image is only adjusted if not set specifically for this mode.
    // - Both the foreground and background images are adjusted.

    if (_adjustsImageWhenHighlighted && state == UIControlStateHighlighted) {
        // Use a pale blue tint to make it look Android-y.
        // Second-lightest blue from http://developer.android.com/design/style/color.html
        UIColor* color = [UIColor colorWithRed:0.773 green:0.918 blue:0.973 alpha:0.5];
        image = [image tintedImageUsingColor:color];
    }
    return image;
}

- (AP_Image*)imageForState:(UIControlState)state
{
    AP_Image* result = [_image objectForKey:[NSNumber numberWithInt:state]];
    if (!result) {
        result = [_image objectForKey:[NSNumber numberWithInt:UIControlStateNormal]];
        result = [self maybeAdjustImage:result forState:state];
    }
    return result;
}

- (AP_Image*)backgroundImageForState:(UIControlState)state
{
    AP_Image* result = [_backgroundImage objectForKey:[NSNumber numberWithInt:state]];
    if (!result) {
        result = [_backgroundImage objectForKey:[NSNumber numberWithInt:UIControlStateNormal]];
        result = [self maybeAdjustImage:result forState:state];
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
        [self setBackgroundColor:[self backgroundColorForState:state]];

        _needsStateRefresh = NO;
    }
}

- (void) updateGL:(float)dt
{
    [self refreshStateIfNeeded];
}

- (void) renderWithBoundsToGL:(CGAffineTransform)boundsToGL alpha:(CGFloat)alpha
{
    [super renderWithBoundsToGL:boundsToGL alpha:alpha];

    UIControlState state = self.highlighted ? UIControlStateHighlighted : UIControlStateNormal;
    AP_Image* image = [self backgroundImageForState:state];
    if (image) {
        CGRect bounds = self.inFlightBounds;
        CGAffineTransform t = CGAffineTransformTranslate(
            boundsToGL,
            bounds.origin.x, bounds.origin.y);

        [image renderGLWithSize:bounds.size transform:t alpha:alpha];
    }
}

@end
