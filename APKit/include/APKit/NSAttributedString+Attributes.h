#pragma once

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

@interface NSMutableAttributedString (Attributes)

+ (instancetype) attributedStringWithString:(NSString*)string;
+ (instancetype) attributedStringWithAttributedString:(NSAttributedString*)attrStr;

- (void) setFont:(UIFont*)font;
- (void) setFont:(UIFont*)font range:(NSRange)range;

- (void) setTextColor:(UIColor*)color;
- (void) setTextColor:(UIColor*)color range:(NSRange)range;

- (void) setParagraphStyle:(NSParagraphStyle*)style;
- (void) setParagraphStyle:(NSParagraphStyle*)style range:(NSRange)range;

@end
