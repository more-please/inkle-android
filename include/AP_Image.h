#import <Foundation/Foundation.h>

#ifdef AP_REPLACE_UI

@interface AP_Image : NSObject

@property (readonly) NSString* assetName;
@property (readonly) CGSize size;
@property (readonly) CGSize pixelSize; // Added by Iain
@property (readonly) CGFloat scale;

+ (AP_Image*) imageNamed:(NSString*)assetName;

- (AP_Image*) resizableImageWithCapInsets:(UIEdgeInsets)capInsets;
- (AP_Image*) stretchableImageWithLeftCapWidth:(NSInteger)leftCapWidth topCapHeight:(NSInteger)topCapHeight;
- (AP_Image*) tintedImageUsingColor:(UIColor*)tintColor;

// Hack to let Joe make flipped and scaled images...
@property(readonly) AP_Image* CGImage; // returns self, not a real CGImageRef
+ (AP_Image*) imageWithCGImage:(AP_Image*)cgImage scale:(CGFloat)scale orientation:(UIImageOrientation)orientation;
- (id) initWithCGImage:(AP_Image*)cgImage scale:(CGFloat)scale orientation:(UIImageOrientation)orientation;

// Draw the image, centered around 0,0.
- (void) renderGLWithTransform:(CGAffineTransform)transform alpha:(CGFloat)alpha;

@end

#else
typedef UIImage AP_Image;
#endif
