#import "NSAttributedString+Attributes.h"

@implementation NSMutableAttributedString (Attributes)

- (void) setFont:(UIFont*)font
{
    NSRange r = NSMakeRange(0, self.length);
    [self setFont:font range:r];
}

- (void) setFont:(UIFont*)font range:(NSRange)range
{
    [self addAttribute:NSFontAttributeName value:font range:range];
}

- (void) setTextColor:(UIColor*)color
{
    NSRange r = NSMakeRange(0, self.length);
    [self setTextColor:color range:r];
}

- (void) setTextColor:(UIColor*)color range:(NSRange)range
{
    [self addAttribute:NSForegroundColorAttributeName value:color range:range];
}

- (void) setParagraphStyle:(NSParagraphStyle*)style
{
    NSRange r = NSMakeRange(0, self.length);
    [self setParagraphStyle:style range:r];
}

- (void) setParagraphStyle:(NSParagraphStyle*)style range:(NSRange)range
{
    [self addAttribute:NSParagraphStyleAttributeName value:style range:range];
}

@end
