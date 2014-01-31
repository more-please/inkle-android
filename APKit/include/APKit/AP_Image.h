#pragma once

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

#ifdef ANDROID
typedef enum UIImageResizingMode {
    UIImageResizingModeTile,
    UIImageResizingModeStretch,
} UIImageResizingMode;
#endif

@interface AP_Image : NSObject

@property (nonatomic,readonly) NSString* assetName;
@property (nonatomic,readonly) CGSize size;
@property (nonatomic,readonly) CGSize pixelSize; // Added by Iain
@property (nonatomic,readonly) UIEdgeInsets insets;
@property (nonatomic,readonly) CGFloat scale;
@property (nonatomic,readonly) UIImageResizingMode resizingMode;

+ (AP_Image*) imageNamed:(NSString*)assetName;

- (AP_Image*) resizableImageWithCapInsets:(UIEdgeInsets)capInsets;
- (AP_Image*) stretchableImageWithLeftCapWidth:(NSInteger)leftCapWidth topCapHeight:(NSInteger)topCapHeight;
- (AP_Image*) tintedImageUsingColor:(UIColor*)tintColor;

// Hack to let Joe make flipped and scaled images...
@property(readonly) AP_Image* CGImage; // returns self, not a real CGImageRef
+ (AP_Image*) imageWithCGImage:(AP_Image*)cgImage scale:(CGFloat)scale orientation:(UIImageOrientation)orientation;
- (id) initWithCGImage:(AP_Image*)cgImage scale:(CGFloat)scale orientation:(UIImageOrientation)orientation;

// Draw the image at the given size, with the top-left at 0,0.
- (void) renderGLWithSize:(CGSize)size transform:(CGAffineTransform)transform alpha:(CGFloat)alpha;

@end
