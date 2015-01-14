#import "NSString+sizeWithFont.h"

#import "AP_Label.h"

@implementation NSString (sizeWithFont)

- (CGSize) sizeWithFont:(UIFont*)font constrainedToSize:(CGSize)size
{
    AP_Label* label = [[AP_Label alloc] init];
    label.numberOfLines = 0;
    label.text = self;
    label.font = font;
    return [label sizeThatFits:size];
}

- (CGSize) sizeWithFont:(UIFont*)font
{
    return [self sizeWithFont:font constrainedToSize:CGSizeMake(FLT_MAX, FLT_MAX)];
}

@end