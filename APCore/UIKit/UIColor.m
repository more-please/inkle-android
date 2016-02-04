#import "UIColor.h"

#import "GlueCommon.h"

// #ifdef ANDROID

size_t CGColorGetNumberOfComponents(CGColorRef color) {
    return 4;
}

// #endif

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
    GLKVector4 rgba = {{white, white, white, alpha}};
    return [UIColor colorWithRgba:rgba];
}

+ (UIColor*) colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue
{
    GLKVector4 rgba = {{red, green, blue, 1.0}};
    return [UIColor colorWithRgba:rgba];
}

+ (UIColor*) colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha
{
    GLKVector4 rgba = {{red, green, blue, alpha}};
    return [UIColor colorWithRgba:rgba];
}

+ (UIColor*) colorWithRgba:(GLKVector4)rgba
{
    UIColor* result = [[UIColor alloc] init];
    result->_rgba = rgba;
    return result;
}

+ (UIColor*) colorWithPatternImage:(AP_Image*)pattern
{
    UIColor* result = [UIColor colorWithRed:1.0f green:0.3f blue:1.0f alpha:0.75f];
    result->_pattern = pattern;
    return result;
}

- (GLKVector4) CGColor
{
    return _rgba;
}

- (BOOL) getWhite:(CGFloat*)white alpha:(CGFloat*)alpha {
    NSLog(@"[UIColor getWhite:alpha:] not implemented!");
    return NO;
}

- (BOOL) getRed:(CGFloat*)red green:(CGFloat*)green blue:(CGFloat*)blue alpha:(CGFloat*)alpha {
    if (_pattern) {
        NSLog(@"*** Tried to get color components from a pattern");
        return NO;
    }
    *red = _rgba.r;
    *green = _rgba.g;
    *blue = _rgba.b;
    *alpha = _rgba.a;
    return YES;
}

- (UIColor*) colorWithAlphaComponent:(CGFloat)alpha {
    if (_pattern) {
        NSLog(@"*** Tried to set alpha of a pattern");
        return nil;
    }
    GLKVector4 rgba = _rgba;
    rgba.a = alpha;
    return [UIColor colorWithRgba:rgba];
}

- (UIColor*) mix:(CGFloat)ratio with:(UIColor *)other
{
    if (other) {
        return [UIColor colorWithRgba:GLKVector4Lerp(_rgba, other.rgba, ratio)];
    } else {
        NSLog(@"ERROR - 'other' was nil in [UIColor mix:with:]");
        return nil;
    }
}

@end
