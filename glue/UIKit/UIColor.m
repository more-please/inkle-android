#import "UIColor.h"

@implementation UIColor

+ (UIColor*) whiteColor
{
    static UIColor* result;
    if (!result) {
        result = [UIColor colorWithWhite:1 alpha:1];
    }
    return result;
}

+ (UIColor*) blackColor
{
    static UIColor* result;
    if (!result) {
        result = [UIColor colorWithWhite:0 alpha:1];
    }
    return result;
}

+ (UIColor*) clearColor
{
    static UIColor* result;
    if (!result) {
        result = [UIColor colorWithWhite:0 alpha:0];
    }
    return result;
}

+ (UIColor*) colorWithWhite:(CGFloat)white alpha:(CGFloat)alpha
{
    GLKVector4 rgba = {white, white, white, alpha};
    return [UIColor colorWithRgba:rgba];
}

+ (UIColor*) colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha
{
    GLKVector4 rgba = {red, green, blue, alpha};
    return [UIColor colorWithRgba:rgba];
}

+ (UIColor*) colorWithRgba:(GLKVector4)rgba
{
    UIColor* result = [[UIColor alloc] init];
    result->_rgba = rgba;
    return result;
}

@end
