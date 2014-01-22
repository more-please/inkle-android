#import "AP_AnimatedProperty.h"

#import "AP_Check.h"
#import "AP_Utils.h"
#import "NSObject+AP_KeepAlive.h"

@implementation AP_AnimatedProperty

static AP_Animation* g_CurrentAnimation = nil;

+ (AP_Animation*) currentAnimation
{
    return g_CurrentAnimation;
}

+ (void) setCurrentAnimation:(AP_Animation*)animation
{
    g_CurrentAnimation = animation;
}

- (id) initWithName:(NSString*)name view:(AP_View*)view
{
    self = [super init];
    if (self) {
        _name = name;
        _view = view;
        [_view animatedPropertyWasAdded:self];
    }
    return self;
}

- (void) setAnimation:(AP_Animation*)animation
{
    if (_animation != animation) {
        if (_animation) {
            [_animation removeProp:self];
        }
        _animation = animation;
        if (_animation) {
            [_animation addProp:self];
        }
    }
}

- (BOOL) maybeJoinCurrentAnimation
{
    if (g_CurrentAnimation) {
        self.animation = g_CurrentAnimation;
        return YES;
    } else {
        return NO;
    }
}

- (void) cancelAnimation
{
    if (_animation) {
        [_animation cancel];
    }
}

- (void) finishAnimation
{
    if (_animation) {
        [_animation finish];
    }
}

- (void) updateWithProgress:(CGFloat)progress
{
}

- (void) animationWasCancelled
{
    _animation = nil;
}

- (void) animationWasFinished
{
    _animation = nil;
}



@end


@implementation AP_AnimatedFloat {
    CGFloat _src;
}

- (void) updateWithProgress:(CGFloat)progress
{
    CGFloat newValue = AP_Lerp(_src, _dest, progress);
    if (self.animation.tag) {
        NSLog(@"  %@.%@: %.2f -> %.2f", self.view, self.name, _inFlight, newValue);
    }
    _inFlight = newValue;
}

- (void) setDest:(CGFloat)dest
{
    if (dest != _dest) {
        if (![self maybeJoinCurrentAnimation]) {
            _src = _inFlight = dest;
        }
        _dest = dest;
    }
}

- (void) animationWasCancelled
{
    _src = _inFlight;
    _dest = _inFlight;
    [super animationWasCancelled];
}

- (void) animationWasFinished
{
    _src = _dest;
    _inFlight = _dest;
    [super animationWasFinished];
}

@end


@implementation AP_AnimatedPoint {
    CGPoint _src;
}

- (void) updateWithProgress:(CGFloat)progress
{
    CGPoint newValue;
    newValue.x = AP_Lerp(_src.x, _dest.x, progress);
    newValue.y = AP_Lerp(_src.y, _dest.y, progress);

    if (self.animation.tag) {
        NSLog(@"  %@.%@: (%.1f,%.1f) -> (%.1f,%.1f)", self.view, self.name, _inFlight.x, _inFlight.y, newValue.x, newValue.y);
    }
    _inFlight = newValue;
}

- (void) setDest:(CGPoint)dest
{
    if (!CGPointEqualToPoint(dest, _dest)) {
        if (![self maybeJoinCurrentAnimation]) {
            _src = _inFlight = dest;
        }
        _dest = dest;
    }
}

- (void) animationWasCancelled
{
    _src = _inFlight;
    _dest = _inFlight;
    [super animationWasCancelled];
}

- (void) animationWasFinished
{
    _src = _dest;
    _inFlight = _dest;
    [super animationWasFinished];
}

@end


@implementation AP_AnimatedSize {
    CGSize _src;
}

- (void) updateWithProgress:(CGFloat)progress
{
    CGSize newValue;
    newValue.width = AP_Lerp(_src.width, _dest.width, progress);
    newValue.height = AP_Lerp(_src.height, _dest.height, progress);

    if (self.animation.tag) {
        NSLog(@"  %@.%@: (%.1f,%.1f) -> (%.1f,%.1f)", self.view, self.name, _inFlight.width, _inFlight.height, newValue.width, newValue.height);
    }
    _inFlight = newValue;
}

- (void) setDest:(CGSize)dest
{
    if (!CGSizeEqualToSize(dest, _dest)) {
        if (![self maybeJoinCurrentAnimation]) {
            _src = _inFlight = dest;
        }
        _dest = dest;
    }
}

- (void) animationWasCancelled
{
    _src = _inFlight;
    _dest = _inFlight;
    [super animationWasCancelled];
}

- (void) animationWasFinished
{
    _src = _dest;
    _inFlight = _dest;
    [super animationWasFinished];
}

@end


@implementation AP_AnimatedVector4 {
    GLKVector4 _src;
}

- (void) updateWithProgress:(CGFloat)progress
{
    for (int i = 0; i < 4; ++i) {
        _inFlight.v[i] = AP_Lerp(_src.v[i], _dest.v[i], progress);
    }
}

- (void) setDest:(GLKVector4)dest
{
    if (!GLKVector4AllEqualToVector4(dest, _dest)) {
        if (![self maybeJoinCurrentAnimation]) {
            _src = _inFlight = dest;
        }
        _dest = dest;
    }
}

- (void) animationWasCancelled
{
    _src = _inFlight;
    _dest = _inFlight;
    [super animationWasCancelled];
}

- (void) animationWasFinished
{
    _src = _dest;
    _inFlight = _dest;
    [super animationWasFinished];
}

@end


@implementation AP_AnimatedTransform {
    CGAffineTransform _src;
}

- (void) updateWithProgress:(CGFloat)progress
{
    _inFlight.a = AP_Lerp(_src.a, _dest.a, progress);
    _inFlight.b = AP_Lerp(_src.b, _dest.b, progress);
    _inFlight.c = AP_Lerp(_src.c, _dest.c, progress);
    _inFlight.d = AP_Lerp(_src.d, _dest.d, progress);
    _inFlight.tx = AP_Lerp(_src.tx, _dest.tx, progress);
    _inFlight.ty = AP_Lerp(_src.ty, _dest.ty, progress);
}

- (void) setDest:(CGAffineTransform)dest
{
    if (!CGAffineTransformEqualToTransform(dest, _dest)) {
        if (![self maybeJoinCurrentAnimation]) {
            _src = _inFlight = dest;
        }
        _dest = dest;
    }
}

- (void) animationWasCancelled
{
    _src = _inFlight;
    _dest = _inFlight;
    [super animationWasCancelled];
}

- (void) animationWasFinished
{
    _src = _dest;
    _inFlight = _dest;
    [super animationWasFinished];
}

@end
