#pragma once

#import <Foundation/Foundation.h>

#import "AP_Font.h"
#import "AP_Label_Text.h"
#import "AP_View.h"

#ifdef AP_REPLACE_UI

@class AP_Font;

@interface AP_Label : AP_View

- (void) setText:(NSString*)text;
- (AP_Label_Text*) text; // Change the return type so we can support sizeWithFont:

// Setters set the corresponding property for the entire string.
- (void) setFont:(AP_Font*)font;
- (void) setTextColor:(UIColor*)color;
- (void) setTextAlignment:(NSTextAlignment)alignment;
- (void) setShadowOffset:(CGSize)offset;
- (void) setShadowColor:(UIColor*)color;
- (void) setLineBreakMode:(NSLineBreakMode)mode;

// Getters get the property at the beginning of the string.
- (AP_Font*)font;
- (UIColor*)textColor;

@property(nonatomic) NSAttributedString* attributedText;
//-(void)resetAttributedText; //!< rebuild the attributedString based on UILabel's text/font/color/alignment/... properties

// Properties of the label rather than the text.
@property(nonatomic) BOOL automaticallyDetectLinks;
@property(nonatomic) BOOL extendBottomToFit;
@property(nonatomic) BOOL centerVertically;
@property(nonatomic) BOOL adjustsFontSizeToFitWidth;
@property(nonatomic) NSInteger numberOfLines;
@property(nonatomic) CGFloat minimumFontSize;

- (void) renderWithBoundsToGL:(CGAffineTransform)boundsToGL alpha:(CGFloat)alpha;

@end

typedef AP_Label OHAttributedLabel;

#else
typedef UILabel AP_Label;
#endif
