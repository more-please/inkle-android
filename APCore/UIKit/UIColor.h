#pragma once

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#ifdef ANDROID
// Don't use CGColor, just use RGBA vectors.
typedef GLKVector4 CGColorRef;

extern size_t CGColorGetNumberOfComponents(CGColorRef color);
#endif

@class AP_Image;

@interface UIColor : NSObject

+ (UIColor*) whiteColor;
+ (UIColor*) blackColor;
+ (UIColor*) grayColor;
+ (UIColor*) clearColor;
+ (UIColor*) redColor;
+ (UIColor*) greenColor;
+ (UIColor*) blueColor;
+ (UIColor*) colorWithWhite:(CGFloat)white alpha:(CGFloat)alpha;
+ (UIColor*) colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue;
+ (UIColor*) colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;

// WTF, Apple. In what way is this a Color?
+ (UIColor*) colorWithPatternImage:(AP_Image*)pattern;
@property(nonatomic,readonly,strong) AP_Image* pattern;

@property(nonatomic,readonly) CGColorRef CGColor;

- (BOOL) getWhite:(CGFloat*)white alpha:(CGFloat*)alpha;
- (BOOL) getRed:(CGFloat*)red green:(CGFloat*)green blue:(CGFloat*)blue alpha:(CGFloat*)alpha;
- (UIColor*) colorWithAlphaComponent:(CGFloat)alpha;

@property(nonatomic,readonly,assign) GLKVector4 rgba;
+ (UIColor*) colorWithRgba:(GLKVector4)rgba;

@end
