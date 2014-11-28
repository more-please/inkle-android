#pragma once

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class AP_Font_Data;

extern AP_Font_Data* fontDataNamed(NSString* name);

@interface UIFont : NSObject

+ (UIFont*) fontWithName:(NSString*)fontName size:(CGFloat)fontSize;
+ (UIFont*) systemFontOfSize:(CGFloat)fontSize;
+ (UIFont*) boldSystemFontOfSize:(CGFloat)fontSize;
+ (UIFont*) italicSystemFontOfSize:(CGFloat)fontSize;

- (UIFont*) fontWithSize:(CGFloat)fontSize;

@property(nonatomic,readonly) NSString* fontName;
@property(nonatomic,readonly) CGFloat pointSize;

// Iain addition
@property(nonatomic,readonly) AP_Font_Data* fontData;

@end
