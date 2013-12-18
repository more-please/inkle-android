#pragma once

#import <Foundation/Foundation.h>

@interface UIFont : NSObject

@property(nonatomic,readonly,retain) NSString* fontName;
@property(nonatomic,readonly) CGFloat pointSize;

+ (UIFont*) fontWithName:(NSString*)fontName size:(CGFloat)fontSize;

- (UIFont*) fontWithSize:(CGFloat)fontSize;

@end
