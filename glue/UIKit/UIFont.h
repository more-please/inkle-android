#pragma once

#import <Foundation/Foundation.h>

@interface UIFont : NSObject

@property(nonatomic,readonly,strong) NSString* fontName;
@property(nonatomic,readonly) CGFloat pointSize;

+ (UIFont*) fontWithName:(NSString*)fontName size:(CGFloat)fontSize;
+ (UIFont*) systemFontOfSize:(CGFloat)fontSize;
+ (UIFont*) boldSystemFontOfSize:(CGFloat)fontSize;
+ (UIFont*) italicSystemFontOfSize:(CGFloat)fontSize;

- (UIFont*) fontWithSize:(CGFloat)fontSize;

- (CGFloat) descender;

@end

// Annoying cyclic dependency: this function is implemented in APKit.
extern CGFloat UIFont_getDescender(UIFont*);