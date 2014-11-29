#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <GLKit/GLKit.h>

@interface NSObject (AP_RoundRect)

- (void) circleWithSize:(CGSize)size
    transform:(CGAffineTransform)transform
    color:(GLKVector4)color;

- (void) roundRectWithSize:(CGSize)size
    transform:(CGAffineTransform)transform
    penColor:(GLKVector4)penColor
    fillColor:(GLKVector4)fillColor
    pen:(CGFloat)pen
    corner:(CGFloat)corner;

@end
