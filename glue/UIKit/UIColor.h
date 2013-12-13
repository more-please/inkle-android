#pragma once

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface UIColor : NSObject

+ (UIColor*) whiteColor;
+ (UIColor*) blackColor;
+ (UIColor*) clearColor;
+ (UIColor*) colorWithWhite:(CGFloat)white alpha:(CGFloat)alpha;
+ (UIColor*) colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;

// Android extensions...
@property(nonatomic,readonly) GLKVector4 rgba;
+ (UIColor*) colorWithRgba:(GLKVector4)rgba;

@end

