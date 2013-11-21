#import <Foundation/Foundation.h>

#import "AP_Font.h"
#import "AP_View.h"

#ifdef AP_REPLACE_UI

@class AP_Font;

@interface AP_Label_Text : NSObject
- (CGFloat) floatValue;
// Wrapping to fit horizontal and vertical size. Text will be wrapped and truncated using the NSLineBreakMode. If the height is less than a line of text, it may return
// a vertical size that is bigger than the one passed in.
// If you size your text using the constrainedToSize: methods below, you should draw the text using the drawInRect: methods using the same line break mode for consistency
- (CGSize) sizeWithFont:(AP_Font*)font constrainedToSize:(CGSize)size; // Uses NSLineBreakModeWordWrap
- (CGSize) sizeWithFont:(AP_Font*)font;
@end

@interface AP_Label : AP_View

- (void) setText:(NSString*)text;
- (AP_Label_Text*) text; // Change the return type so we can support sizeWithFont:

@property(nonatomic) AP_Font* font; // default is nil (system font 17 plain)
@property(nonatomic) UIColor* textColor; // default is nil (text draws black)
@property(nonatomic) UIColor* shadowColor; // default is nil (no shadow)
@property(nonatomic) CGSize shadowOffset; // default is CGSizeMake(0, -1) -- a top shadow
@property(nonatomic) NSTextAlignment textAlignment; // default is NSTextAlignmentLeft
@property(nonatomic) NSInteger numberOfLines; // default is 1 (single line)
@property(nonatomic) NSLineBreakMode lineBreakMode; // default is NSLineBreakByTruncatingTail
@property(nonatomic) BOOL adjustsFontSizeToFitWidth; // default is NO
@property(nonatomic) CGFloat minimumFontSize; // default is 0.0
@property(nonatomic) BOOL centerVertically;
@property(nonatomic) BOOL extendBottomToFit;

@property(nonatomic) NSAttributedString* attributedText;
//-(void)resetAttributedText; //!< rebuild the attributedString based on UILabel's text/font/color/alignment/... properties

@property(nonatomic, assign) BOOL automaticallyDetectLinks; //!< Defaults to YES

- (void) renderWithBoundsToGL:(CGAffineTransform)boundsToGL alpha:(CGFloat)alpha;

@end

#else
typedef UILabel AP_Label;
#endif
