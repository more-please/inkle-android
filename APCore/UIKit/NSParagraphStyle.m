#import "NSParagraphStyle.h"

#import "GlueCommon.h"

NSString* const AP_UrlAttributeName = @"AP_Url";
NSString* const AP_ImageAttributeName = @"AP_Image";
NSString* const AP_TextTransformAttributeName = @"AP_TextTransform";

#ifndef APPLE_RUNTIME

NSString* const NSParagraphStyleAttributeName = @"NSParagraphStyle";
NSString* const NSFontAttributeName = @"NSFont";
NSString* const NSKernAttributeName = @"NSKern";
NSString* const NSForegroundColorAttributeName = @"NSForegroundColor";

@implementation NSParagraphStyle

+ (NSParagraphStyle*) defaultParagraphStyle
{
    static NSParagraphStyle* s_default;
    if (!s_default) {
        s_default = [[NSParagraphStyle alloc] init];
    }
    return s_default;
}

- (id) copyWithZone:(NSZone*)zone
{
    return [self mutableCopyWithZone:zone];
}

- (id) mutableCopyWithZone:(NSZone*)zone
{
    NSParagraphStyle* other = [[NSMutableParagraphStyle alloc] init];
    other->_lineSpacing = _lineSpacing;
    other->_alignment = _alignment;
    other->_firstLineHeadIndent = _firstLineHeadIndent;
    other->_headIndent = _headIndent;
    other->_tailIndent = _tailIndent;
    other->_paragraphSpacing = _paragraphSpacing;
    other->_paragraphSpacingBefore = _paragraphSpacingBefore;
    other->_lineBreakMode = _lineBreakMode;
    return other;
}

@end

@implementation NSMutableParagraphStyle
@end

#endif
