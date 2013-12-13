#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

// Animatable properties of an AP_View.
@interface AP_AnimationProps : NSObject <NSCopying>

@property (nonatomic,assign) CGRect frame;
@property (nonatomic,assign) CGRect bounds;
@property (nonatomic,assign) CGPoint center;
@property (nonatomic,assign) CGAffineTransform transform;
@property (nonatomic,assign) CGFloat alpha;
@property (nonatomic) GLKVector4 backgroundColor;

- (void) lerpFrom:(AP_AnimationProps*)src to:(AP_AnimationProps*)dest atTime:(CGFloat)time;

- (void) copyFrom:(AP_AnimationProps*)other;

@end
