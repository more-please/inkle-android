#import <Foundation/Foundation.h>

#ifdef AP_REPLACE_UI

@interface AP_Layer : NSObject

@property CGFloat zPosition;

@property CGColorRef shadowColor; // Default is black
@property float shadowOpacity; // Default is 0
@property CGSize shadowOffset; // Default is (0, -3)
@property CGFloat shadowRadius; // Default is 3

@property AP_Layer* mask; // Wow, I hope nobody actually uses this
@property CGPoint anchorPoint; // Default is (0.5, 0.5), i.e. the center of the bounds rect
@property CGPoint position;

- (void)removeAllAnimations;

@end

#else
typedef CALayer AP_Layer;
#endif