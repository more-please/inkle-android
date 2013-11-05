#import <Foundation/Foundation.h>

#import "AP_View.h"

#ifdef AP_REPLACE_UI

@interface AP_Label : AP_View

@property NSString* text; // default is nil
@property UIFont* font; // default is nil (system font 17 plain)
@property UIColor* textColor; // default is nil (text draws black)
@property UIColor* shadowColor; // default is nil (no shadow)
@property NSTextAlignment textAlignment; // default is NSTextAlignmentLeft
@property NSInteger numberOfLines; // default is 1 (single line)
@property NSLineBreakMode lineBreakMode; // default is NSLineBreakByTruncatingTail
@property BOOL adjustsFontSizeToFitWidth; // default is NO

@end

#else
typedef UILabel AP_Label;
#endif
