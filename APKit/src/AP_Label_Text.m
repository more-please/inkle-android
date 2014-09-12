#import "AP_Label_Text.h"

#import "AP_Font.h"
#import "AP_Label.h"

@implementation NSString (AP_Label_Text)

- (CGSize) sizeWithFont:(AP_Font*)font constrainedToSize:(CGSize)size
{
    AP_Label* label = [[AP_Label alloc] init];
    label.numberOfLines = 0;
    label.text = self;
    label.font = font;
    return [label sizeThatFits:size];
}

- (CGSize) sizeWithFont:(AP_Font*)font
{
    return [self sizeWithFont:font constrainedToSize:CGSizeMake(FLT_MAX, FLT_MAX)];
}

@end
