#import <Foundation/Foundation.h>

#import "AP_Font.h"
#import "AP_View.h"

#ifdef AP_REPLACE_UI

@interface AP_Label : AP_View

@property(nonatomic) NSString* text; // default is nil
@property(nonatomic) AP_Font* font; // default is nil (system font 17 plain)
@property(nonatomic) UIColor* textColor; // default is nil (text draws black)
@property(nonatomic) UIColor* shadowColor; // default is nil (no shadow)
@property(nonatomic) CGSize shadowOffset; // default is CGSizeMake(0, -1) -- a top shadow
@property(nonatomic) NSTextAlignment textAlignment; // default is NSTextAlignmentLeft
@property(nonatomic) NSInteger numberOfLines; // default is 1 (single line)
@property(nonatomic) NSLineBreakMode lineBreakMode; // default is NSLineBreakByTruncatingTail
@property(nonatomic) BOOL adjustsFontSizeToFitWidth; // default is NO
@property(nonatomic) CGFloat minimumFontSize; // default is 0.0

- (void) drawTextInRect:(CGRect)rect;
- (void) drawAttributedText:(NSMutableAttributedString*)text inRect:(CGRect)rect;

@end

#else
typedef UILabel AP_Label;
#endif
