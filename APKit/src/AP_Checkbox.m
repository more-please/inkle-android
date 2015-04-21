#import "AP_Checkbox.h"

#import "AP_Check.h"
#import "AP_ImageView.h"

@implementation AP_Checkbox {
    AP_ImageView* _box;
    AP_ImageView* _tick;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _box = [[AP_ImageView alloc] initWithImage:[AP_Image imageNamed:@"checkbox.png"]];
        _tick = [[AP_ImageView alloc] initWithImage:[AP_Image imageNamed:@"tick.png"]];
        _icon = [[AP_ImageView alloc] init];

        [self addSubview:_box];
        [self addSubview:_tick];
        [self addSubview:_icon];
    }
    return self;
}

- (CGSize) sizeThatFits:(CGSize)size
{
    CGSize boxSize = _box.image.size;
    return CGSizeMake(MIN(2 * boxSize.width, size.width), boxSize.height);
}

- (void) layoutSubviews
{
    const CGRect bounds = self.bounds;
    const CGSize boxSize = _box.image.size;
    const CGRect boxRect = CGRectMake(
        0,
        0.5 * (bounds.size.height - boxSize.height),
        boxSize.width,
        boxSize.height);

    _box.frame = boxRect;
    _tick.frame = boxRect;

    _box.alpha = self.isEnabled ? 1 : 0.5;

    if (self.isHighlighted) {
        _tick.alpha = 0.5;
    } else if (self.isSelected) {
        _tick.alpha = self.isEnabled ? 1 : 0.5;
    } else {
        _tick.alpha = 0;
    }

    CGRect imageRect = boxRect;
    imageRect.origin.x += boxRect.size.width;
    _icon.frame = imageRect;
    _icon.alpha = self.isEnabled ? 1 : 0.5;
}

- (void) setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setNeedsLayout];
    [AP_View animateWithDuration:0.1f delay:0
        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
        animations:^{
            [self layoutIfNeeded];
        }
        completion:nil
    ];
}

- (void) setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self setNeedsLayout];
    [AP_View animateWithDuration:0.1f delay:0
        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
        animations:^{
            [self layoutIfNeeded];
        }
        completion:nil
    ];
}

@end
