#pragma once

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

// Don't use CGColor, just use RGBA vectors.
typedef GLKVector4 CGColorRef;

extern size_t CGColorGetNumberOfComponents(CGColorRef color);

@interface UIColor : NSObject

+ (UIColor*) whiteColor;
+ (UIColor*) blackColor;
+ (UIColor*) grayColor;
+ (UIColor*) clearColor;
+ (UIColor*) redColor;
+ (UIColor*) greenColor;
+ (UIColor*) blueColor;
+ (UIColor*) colorWithWhite:(CGFloat)white alpha:(CGFloat)alpha;
+ (UIColor*) colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;

@property(nonatomic,readonly) CGColorRef CGColor;

- (BOOL) getWhite:(CGFloat*)white alpha:(CGFloat*)alpha;
- (BOOL) getRed:(CGFloat*)red green:(CGFloat*)green blue:(CGFloat*)blue alpha:(CGFloat*)alpha;

// Android extensions...
@property(nonatomic,readonly,assign) GLKVector4 rgba;
+ (UIColor*) colorWithRgba:(GLKVector4)rgba;

@end
