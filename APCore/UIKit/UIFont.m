#import "UIFont.h"

#import "GlueCommon.h"

@implementation UIFont

+ (UIFont*) fontWithName:(NSString *)fontName size:(CGFloat)fontSize
{
    UIFont* result = [[UIFont alloc] init];
    result->_fontName = fontName;
    result->_pointSize = fontSize;
    result->_fontData = fontDataNamed(fontName);
    if (!result->_fontData) {
        return nil;
    }
    return result;
}

+ (UIFont*) systemFontOfSize:(CGFloat)fontSize
{
    return [UIFont fontWithName:@"Helvetica" size:fontSize];
}

+ (UIFont*) boldSystemFontOfSize:(CGFloat)fontSize
{
    return [UIFont fontWithName:@"Helvetica-Bold" size:fontSize];
}

+ (UIFont*) italicSystemFontOfSize:(CGFloat)fontSize
{
    return [UIFont fontWithName:@"Helvetica-Oblique" size:fontSize];
}

- (UIFont*) fontWithSize:(CGFloat)fontSize
{
    if (fontSize == _pointSize) {
        return self;
    } else {
        UIFont* result = [[UIFont alloc] init];
        result->_pointSize = fontSize;
        result->_fontName = _fontName;
        result->_fontData = _fontData;
        return result;
    }
}

@end
