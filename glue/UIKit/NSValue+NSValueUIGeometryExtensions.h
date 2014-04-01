#import "UIDefines.h"

@interface NSValue (NSValueUIGeometryExtensions)

+ (NSValue*) valueWithCGPoint:(CGPoint)point;

- (CGPoint)CGPointValue;

@end
