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
        _tick = [[AP_ImageView alloc] initWithImage:[AP_Image imageNamed:@"checkbox.png"]];

        [self addSubview:_box];
        [self addSubview:_tick];
    }
    return self;
}

- (CGSize) sizeThatFits:(CGSize)size
{
    CGSize boxSize = _box.image.size;
    return CGSizeMake(MIN(boxSize.width, size.width), boxSize.height);
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

    const CGAffineTransform grow = CGAffineTransformMakeScale(1.5, 1.5);
    const CGAffineTransform shrink = CGAffineTransformMakeScale(0.1, 0.1);

    _box.transform = self.isHighlighted ? grow : CGAffineTransformIdentity;
    _box.alpha = self.isEnabled ? 1 : 0.5;

    if (self.isSelected) {
        _tick.transform = CGAffineTransformMakeRotation(2);
        _tick.alpha = self.isEnabled ? 1 : 0.5;
    } else {
        _tick.transform = shrink;
        _tick.alpha = 0;
    }
    _tick.backgroundColor = [UIColor colorWithRed:1 green:0.3 blue:0.2 alpha:0.5];
}

- (void) setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setNeedsLayout];
    [AP_View animateWithDuration:2.0f delay:0
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
    [AP_View animateWithDuration:2.0f delay:0
        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
        animations:^{
            [self layoutIfNeeded];
        }
        completion:nil
    ];
}

@end
