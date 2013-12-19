#import "CoreGraphics.h"

#import <Foundation/NSGeometry.h>

const CGPoint CGPointZero = {0, 0};
const CGSize CGSizeZero = {0, 0};
const CGRect CGRectZero = {{0, 0}, {0, 0}};
const CGRect CGRectNull = {{INFINITY, INFINITY}, {0, 0}};

const CGAffineTransform CGAffineTransformIdentity = { 1, 0, 0, 1, 0, 0 };

CGPoint CGPointFromString(NSString* s) {
    NSPoint ns = NSPointFromString(s);
    CGPoint cg = { ns.x, ns.y };
    return cg;
}

NSString* NSStringFromCGPoint(CGPoint p) {
    NSPoint ns = {p.x, p.y};
    return NSStringFromPoint(ns);
}

CGRect CGRectFromString(NSString* s) {
    NSRect ns = NSRectFromString(s);
    CGRect r = {{ns.origin.x, ns.origin.y}, {ns.size.width, ns.size.height}};
    return r;
}

NSString* NSStringFromCGRect(CGRect r) {
    NSRect ns = {{r.origin.x, r.origin.y}, {r.size.width, r.size.height}};
    return NSStringFromRect(ns);
}
