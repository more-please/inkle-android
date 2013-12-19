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
    _imageView.contentMode = UIViewContentModeCenter;

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
    CGRect bounds = self.bounds;
    _titleLabel.frame = UIEdgeInsetsInsetRect(bounds, _titleEdgeInsets);
    _imageView.frame = UIEdgeInsetsInsetRect(bounds, _imageEdgeInsets);
}

- (void) setTitle:(NSString*)title forState:(UIControlState)state
{
    [_title setObject:title forKey:[NSNumber numberWithInt:state]];
    _needsStateRefresh = YES;
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
    _needsStateRefresh = YES;
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
    _needsStateRefresh = YES;
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

- (void) renderSelfAndChildrenWithFrameToGL:(CGAffineTransform)frameToGL alpha:(CGFloat)alpha
{
    [self refreshStateIfNeeded];
    [super renderSelfAndChildrenWithFrameToGL:frameToGL alpha:alpha];
}

- (void) renderWithBoundsToGL:(CGAffineTransform)boundsToGL alpha:(CGFloat)alpha
{
    UIControlState state = self.highlighted ? UIControlStateHighlighted : UIControlStateNormal;
    AP_Image* image = [self backgroundImageForState:state];
    if (image) {
        AP_AnimationProps* props = self.inFlightProps;
        CGRect bounds = props.bounds;
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
