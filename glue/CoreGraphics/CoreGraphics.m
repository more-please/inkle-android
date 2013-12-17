#import "CoreGraphics.h"

const CGPoint CGPointZero = {0, 0};
const CGSize CGSizeZero = {0, 0};
const CGRect CGRectZero = {{0, 0}, {0, 0}};
const CGRect CGRectNull = {{-1e6, -1e6}, {2e6, 2e6}};

const CGAffineTransform CGAffineTransformIdentity = { 1, 0, 0, 1, 0, 0 };

CGPoint CGPointFromString(NSString* string) {
    NSPoint ns = NSPointFromString(string);
    CGPoint cg = { ns.x, ns.y };
    return cg;
}