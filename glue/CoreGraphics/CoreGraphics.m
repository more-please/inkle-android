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

CGRect CGRectUnion(CGRect r1, CGRect r2) {
    if (CGRectIsNull(r1)) return r2;
    if (CGRectIsNull(r2)) return r1;
    CGFloat x1 = MIN(CGRectGetMinX(r1), CGRectGetMinX(r2));
    CGFloat x2 = MAX(CGRectGetMaxX(r1), CGRectGetMaxX(r2));
    CGFloat y1 = MIN(CGRectGetMinY(r1), CGRectGetMinY(r2));
    CGFloat y2 = MAX(CGRectGetMaxY(r1), CGRectGetMaxY(r2));
    return CGRectMake(x1, y1, x2-x1, y2-y1);
}

CGRect CGRectIntersection(CGRect r1, CGRect r2) {
    CGFloat x0 = MAX(CGRectGetMinX(r1), CGRectGetMinX(r2));
    CGFloat y0 = MAX(CGRectGetMinY(r1), CGRectGetMinY(r2));
    CGFloat x1 = MIN(CGRectGetMaxX(r1), CGRectGetMaxX(r2));
    CGFloat y1 = MIN(CGRectGetMaxY(r1), CGRectGetMaxY(r2));
    if (x1 < x0 || y1 < y0) {
        return CGRectNull;
    }
    return CGRectMake(x0, y0, x1-x0, y1-y0);
}

