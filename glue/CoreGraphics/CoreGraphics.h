#pragma once

#import <Foundation/NSObjcRuntime.h>

struct CGPoint {
  CGFloat x;
  CGFloat y;
};
typedef struct CGPoint CGPoint;

struct CGSize {
  CGFloat width;
  CGFloat height;
};
typedef struct CGSize CGSize;

struct CGVector {
  CGFloat dx;
  CGFloat dy;
};
typedef struct CGVector CGVector;

struct CGRect {
  CGPoint origin;
  CGSize size;
};
typedef struct CGRect CGRect;

enum CGRectEdge {
  CGRectMinXEdge, CGRectMinYEdge, CGRectMaxXEdge, CGRectMaxYEdge
};
typedef enum CGRectEdge CGRectEdge;

extern const CGPoint CGPointZero;
extern const CGSize CGSizeZero;
extern const CGRect CGRectZero;
extern const CGRect CGRectNull;

extern CGPoint CGPointFromString(NSString*);
extern NSString* NSStringFromCGPoint(CGPoint);

extern CGRect CGRectFromString(NSString*);
extern NSString* NSStringFromCGRect(CGRect);

extern CGRect CGRectUnion(CGRect r1, CGRect r2);
extern CGRect CGRectIntersection(CGRect r1, CGRect r2);

// Note: assuming non-negative-sized rects...

static inline CGFloat CGRectGetMinX(CGRect rect) {
    return rect.origin.x;
}

static inline CGFloat CGRectGetMidX(CGRect rect) {
    return rect.origin.x + 0.5 * rect.size.width;
}

static inline CGFloat CGRectGetMaxX(CGRect rect) {
    return rect.origin.x + rect.size.width;
}

static inline CGFloat CGRectGetMinY(CGRect rect) {
    return rect.origin.y;
}

static inline CGFloat CGRectGetMidY(CGRect rect) {
    return rect.origin.y + 0.5 * rect.size.height;
}

static inline CGFloat CGRectGetMaxY(CGRect rect) {
    return rect.origin.y + rect.size.height;
}

static inline CGFloat CGRectGetWidth(CGRect rect) {
    return rect.size.width;
}

static inline CGFloat CGRectGetHeight(CGRect rect) {
    return rect.size.height;
}

static inline CGPoint CGPointMake(CGFloat x, CGFloat y) {
    CGPoint p;
    p.x = x;
    p.y = y;
    return p;
}

static inline CGSize CGSizeMake(CGFloat width, CGFloat height) {
    CGSize size;
    size.width = width;
    size.height = height;
    return size;
}

static inline CGVector CGVectorMake(CGFloat dx, CGFloat dy) {
    CGVector v;
    v.dx = dx;
    v.dy = dy;
    return v;
}

static inline CGRect CGRectMake(CGFloat x, CGFloat y, CGFloat width, CGFloat height) {
    CGRect rect;
    rect.origin.x = x;
    rect.origin.y = y;
    rect.size.width = width;
    rect.size.height = height;
    return rect;
}

static inline CGRect CGRectInset(CGRect rect, CGFloat dx, CGFloat dy) {
    rect.origin.x += dx;
    rect.origin.y += dy;
    rect.size.width -= 2 * dx;
    rect.size.height -= 2 * dy;
    return rect;
}

static inline bool CGPointEqualToPoint(CGPoint point1, CGPoint point2) {
    return point1.x == point2.x
        && point1.y == point2.y;
}

static inline bool CGSizeEqualToSize(CGSize size1, CGSize size2) {
    return size1.width == size2.width
        && size1.height == size2.height;
}

static inline bool CGRectEqualToRect(CGRect rect1, CGRect rect2) {
    return CGPointEqualToPoint(rect1.origin, rect2.origin)
        && CGSizeEqualToSize(rect2.size, rect2.size);
}

static inline bool CGRectIsNull(CGRect rect) {
    return CGRectEqualToRect(rect, CGRectNull);
}

static inline bool CGRectContainsPoint(CGRect rect, CGPoint point) {
    return point.x >= rect.origin.x
        && point.x <= (rect.origin.x + rect.size.width)
        && point.y >= rect.origin.y
        && point.y <= (rect.origin.y + rect.size.height);
}

// CGAffineTransform algorithms borrowed from GNUstep.

struct CGAffineTransform {
    CGFloat a, b, c, d;
    CGFloat tx, ty;
};
typedef struct CGAffineTransform CGAffineTransform;

extern const CGAffineTransform CGAffineTransformIdentity;

static inline CGAffineTransform CGAffineTransformMake(
    CGFloat a, CGFloat b, CGFloat c, CGFloat d, CGFloat tx, CGFloat ty)
{
    CGAffineTransform t = { a, b, c, d, tx, ty };
    return t;
}

static inline bool CGAffineTransformEqualToTransform(CGAffineTransform t1, CGAffineTransform t2) {
    return t1.a == t2.a
        && t1.b == t2.b
        && t1.c == t2.c
        && t1.d == t2.d
        && t1.tx == t2.tx
        && t1.ty == t2.ty;
}

static inline CGAffineTransform CGAffineTransformConcat(CGAffineTransform t1, CGAffineTransform t2) {
    CGAffineTransform result;
    result.a = t1.a * t2.a + t1.b * t2.c;
    result.b = t1.a * t2.b + t1.b * t2.d;
    result.c = t1.c * t2.a + t1.d * t2.c;
    result.d = t1.c * t2.b + t1.d * t2.d;
    result.tx = t1.tx * t2.a + t1.ty * t2.c + t2.tx;
    result.ty = t1.tx * t2.b + t1.ty * t2.d + t2.ty;
    return result;
}

static inline CGAffineTransform CGAffineTransformMakeTranslation(CGFloat tx, CGFloat ty) {
    CGAffineTransform result = { 1, 0, 0, 1, tx, ty };
    return result;
}

static inline CGAffineTransform CGAffineTransformMakeScale(CGFloat sx, CGFloat sy) {
    CGAffineTransform result = { sx, 0, 0, sy, 0, 0 };
    return result;
}

static inline CGAffineTransform CGAffineTransformMakeRotation(CGFloat angle) {
    CGFloat c = cos(angle);
    CGFloat s = sin(angle);
    CGAffineTransform result = { c, -s, s, c, 0, 0 };
    return result;
}

static inline CGAffineTransform CGAffineTransformTranslate(CGAffineTransform t, CGFloat tx, CGFloat ty) {
    t.tx += tx * t.a + ty * t.c;
    t.ty += tx * t.b + ty * t.d;
    return t;
}

static inline CGAffineTransform CGAffineTransformScale(CGAffineTransform t, CGFloat sx, CGFloat sy) {
    t.a *= sx;
    t.b *= sx;
    t.c *= sy;
    t.d *= sy;
    return t;
}

static inline CGAffineTransform CGAffineTransformRotate(CGAffineTransform t, CGFloat angle) {
    return CGAffineTransformConcat(CGAffineTransformMakeRotation(angle), t);
}

static inline CGAffineTransform CGAffineTransformInvert(CGAffineTransform t) {
  CGAffineTransform inv;
  double det = { t.a * t.d - t.b * t.c };
  if (det == 0) {
    NSLog(@"CGAffineTransformInvert: Cannot invert matrix, determinant is 0");
    return t;
  }
  inv.a = t.d / det;
  inv.b = -t.b / det;
  inv.c = -t.c / det;
  inv.d = t.a / det;
  inv.tx = (t.c * t.ty - t.d * t.tx) / det;
  inv.ty = (t.b * t.tx - t.a * t.ty) / det;
  return inv;
}

static inline bool CGAffineTransformIsIdentity(CGAffineTransform t) {
    return CGAffineTransformEqualToTransform(t, CGAffineTransformIdentity);
}

static inline CGPoint CGPointApplyAffineTransform(CGPoint point, CGAffineTransform t)
{
    CGPoint p;
    p.x = (CGFloat)((double)t.a * point.x + (double)t.c * point.y + t.tx);
    p.y = (CGFloat)((double)t.b * point.x + (double)t.d * point.y + t.ty);
    return p;
}

static inline CGSize CGSizeApplyAffineTransform(CGSize size, CGAffineTransform t)
{
    CGSize s;
    s.width = (CGFloat)((double)t.a * size.width + (double)t.c * size.height);
    s.height = (CGFloat)((double)t.b * size.width + (double)t.d * size.height);
    return s;
}
