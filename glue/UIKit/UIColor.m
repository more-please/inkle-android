#import "UIColor.h"

size_t CGColorGetNumberOfComponents(CGColorRef color) {
    return 4;
}

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

+ (UIColor*) grayColor
{
    static UIColor* result;
    if (!result) {
        result = [UIColor colorWithWhite:0.5 alpha:1];
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

+ (UIColor*) redColor
{
    static UIColor* result;
    if (!result) {
        result = [UIColor colorWithRed:1 green:0 blue:0 alpha:1];
    }
    return result;
}

+ (UIColor*) greenColor
{
    static UIColor* result;
    if (!result) {
        result = [UIColor colorWithRed:0 green:1 blue:0 alpha:1];
    }
    return result;
}

+ (UIColor*) blueColor
{
    static UIColor* result;
    if (!result) {
        result = [UIColor colorWithRed:0 green:0 blue:1 alpha:1];
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

- (CGColorRef) CGColor
{
    return _rgba;
}

- (BOOL) getWhite:(CGFloat*)white alpha:(CGFloat*)alpha {
    AP_NOT_IMPLEMENTED;
    return NO;
}

- (BOOL) getRed:(CGFloat*)red green:(CGFloat*)green blue:(CGFloat*)blue alpha:(CGFloat*)alpha {
    *red = _rgba.r;
    *green = _rgba.g;
    *blue = _rgba.b;
    *alpha = _rgba.a;
    return YES;
}

@end
