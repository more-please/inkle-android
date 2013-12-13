#import "UIFont.h"

@implementation UIFont

+ (UIFont*) fontWithName:(NSString*)name size:(CGFloat)size
{
    UIFont* result = [[UIFont alloc] init];
    result->_fontName = name;
    result->_pointSize = size;
    return result;
}

@end