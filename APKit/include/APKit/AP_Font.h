#pragma once

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

#import "AP_Font_Run.h"

#define AP_Font UIFont

@interface UIFont (AP)

@property(nonatomic,readonly) CGFloat ascender;
@property(nonatomic,readonly) CGFloat descender;
@property(nonatomic,readonly) CGFloat lineHeight;
@property(nonatomic,readonly) CGFloat leading;

- (AP_Font_Run*) runForString:(NSString*)string kerning:(CGFloat)kerning;
- (AP_Font_Run*) runForChars:(unichar*)chars size:(size_t)size kerning:(CGFloat)kerning;

@end
