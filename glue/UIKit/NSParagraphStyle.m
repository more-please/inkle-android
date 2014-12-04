#import "NSParagraphStyle.h"

#import "GlueCommon.h"

NSString* const NSParagraphStyleAttributeName = @"NSParagraphStyle";
NSString* const NSFontAttributeName = @"NSFont";
NSString* const NSKernAttributeName = @"NSKern";
NSString* const NSForegroundColorAttributeName = @"NSForegroundColor";

NSString* const AP_UrlAttributeName = @"AP_Url";
NSString* const AP_ImageAttributeName = @"AP_Image";
NSString* const AP_TextTransformAttributeName = @"AP_TextTransform";

@implementation NSParagraphStyle

+ (NSParagraphStyle*) defaultParagraphStyle
{
    static NSParagraphStyle* s_default;
    if (!s_default) {
        s_default = [[NSParagraphStyle alloc] init];
    }
    return s_default;
}

@end

@implementation NSMutableParagraphStyle
@end
