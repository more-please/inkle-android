#import "NSValue+NSValueUIGeometryExtensions.h"

@implementation NSValue (NSValueUIGeometryExtensions)

+ (NSValue*) valueWithCGPoint:(CGPoint)point
{
    NSPoint p = {point.x, point.y};
    return [NSValue valueWithPoint:p];
}

- (CGPoint)CGPointValue
{
    NSPoint p = [self pointValue];
    CGPoint result = {p.x, p.y};
    return result;
}

@end
