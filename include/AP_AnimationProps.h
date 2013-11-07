#import <Foundation/Foundation.h>

// Animatable properties of an AP_View.
@interface AP_AnimationProps : NSObject <NSCopying>

@property (nonatomic) CGRect frame;
@property (nonatomic) CGRect bounds;
@property (nonatomic) CGPoint center;
@property (nonatomic) CGAffineTransform transform;
@property (nonatomic) CGFloat alpha;
@property (nonatomic) UIColor* backgroundColor;

- (void) lerpFrom:(AP_AnimationProps*)src to:(AP_AnimationProps*)dest atTime:(CGFloat)time;

- (void) copyFrom:(AP_AnimationProps*)other;

@end
