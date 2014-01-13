#import "AP_AnimationProps.h"

#import "AP_Check.h"
#import "AP_Utils.h"
#import "NSObject+AP_KeepAlive.h"

@implementation AP_AnimationProps

- (id) init
{
    self = [super init];
    if (self) {
        _bounds = CGRectMake(0, 0, 0, 0);
        _frame = CGRectMake(0, 0, 0, 0);
        _anchorPoint = CGPointMake(0.5, 0.5);
        _alpha = 1.0;
        _transform = CGAffineTransformIdentity;
        _backgroundColor = GLKVector4Make(0, 0, 0, 0);
    }
    return self;
}

- (id) copyWithZone:(NSZone*)zone
{
    AP_AnimationProps* dup = [[AP_AnimationProps allocWithZone:zone] init];
    [dup copyFrom:self];
    return dup;
}

- (void) copyFrom:(AP_AnimationProps*)other
{
    AP_CHECK(other, return);
    _frame = other->_frame;
    _bounds = other->_bounds;
    _anchorPoint = other->_anchorPoint;
    _transform = other->_transform;
    _alpha = other->_alpha;
    _backgroundColor = other->_backgroundColor;
}

static inline CGSize lerpSize(CGSize src, CGSize dest, CGFloat time) {
    return CGSizeMake(
        AP_Lerp(src.width, dest.width, time),
        AP_Lerp(src.height, dest.height, time));
}

static inline CGPoint lerpPoint(CGPoint src, CGPoint dest, CGFloat time) {
    return CGPointMake(
        AP_Lerp(src.x, dest.x, time),
        AP_Lerp(src.y, dest.y, time));
}

static inline CGRect lerpRect(CGRect src, CGRect dest, CGFloat time) {
    CGRect result;
    result.origin = lerpPoint(src.origin, dest.origin, time);
    result.size = lerpSize(src.size, dest.size, time);
    return result;
}

static inline GLKVector4 lerpVector(GLKVector4 src, GLKVector4 dest, CGFloat time) {
    return GLKVector4Make(
        AP_Lerp(src.r, dest.r, time),
        AP_Lerp(src.g, dest.g, time),
        AP_Lerp(src.b, dest.b, time),
        AP_Lerp(src.a, dest.a, time)
    );
}

- (void) lerpFrom:(AP_AnimationProps *)src to:(AP_AnimationProps *)dest atTime:(CGFloat)time
{
    AP_CHECK(src, return);
    AP_CHECK(dest, return);
    time = AP_CLAMP(time, 0, 1);
    _bounds = lerpRect(src->_bounds, dest->_bounds, time);
    _frame = lerpRect(src->_frame, dest->_frame, time);
    _anchorPoint = lerpPoint(src->_anchorPoint, dest->_anchorPoint, time);
    _alpha = AP_Lerp(src->_alpha, dest->_alpha, time);

    // This probably won't be quite right for rotations, but what the hell..
    _transform.a = AP_Lerp(src->_transform.a, dest->_transform.a, time);
    _transform.b = AP_Lerp(src->_transform.b, dest->_transform.b, time);
    _transform.c = AP_Lerp(src->_transform.c, dest->_transform.c, time);
    _transform.d = AP_Lerp(src->_transform.d, dest->_transform.d, time);
    _transform.tx = AP_Lerp(src->_transform.tx, dest->_transform.tx, time);
    _transform.ty = AP_Lerp(src->_transform.ty, dest->_transform.ty, time);

    _backgroundColor = lerpVector(src->_backgroundColor, dest->_backgroundColor, time);
}

- (void) setBounds:(CGRect)r
{
    CGSize sizeDiff = CGSizeMake(r.size.width - _bounds.size.width, r.size.height - _bounds.size.height);
    _bounds = r;
    _frame.origin.x -= sizeDiff.width * _anchorPoint.x;
    _frame.origin.y -= sizeDiff.height * _anchorPoint.y;
    _frame.size.width += sizeDiff.width;
    _frame.size.height += sizeDiff.height;
}

- (void) setFrame:(CGRect)r
{
    CGSize sizeDiff = CGSizeMake(r.size.width - _frame.size.width, r.size.height - _frame.size.height);
    _frame = r;
    _bounds.size.width += sizeDiff.width;
    _bounds.size.height += sizeDiff.height;
}

- (CGPoint) center
{
    return CGPointMake(
        _frame.origin.x + _frame.size.width * _anchorPoint.x,
        _frame.origin.y + _frame.size.height * _anchorPoint.y);
}

- (void) setCenter:(CGPoint)p
{
    CGPoint delta = CGPointMake(p.x - self.center.x, p.y - self.center.y);
    _frame.origin.x += delta.x;
    _frame.origin.y += delta.y;
}

- (void) setAnchorPoint:(CGPoint)p
{
    CGPoint oldCenter = self.center;
    _anchorPoint = p;
    CGPoint newCenter = self.center;

    // Adjust frame, so that center actually stays in the same place.
    CGPoint delta = CGPointMake(oldCenter.x - newCenter.x, oldCenter.y - newCenter.y);
    _frame.origin.x += delta.x;
    _frame.origin.y += delta.y;
}

@end