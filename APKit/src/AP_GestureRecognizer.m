#import "AP_GestureRecognizer.h"

#import "AP_Check.h"

@implementation AP_GestureRecognizer

- (id) initWithTarget:(id)target action:(SEL)action
{
    self = [super init];
    if (self) {
        AP_NOT_IMPLEMENTED;
    }
    return self;
}

- (CGPoint) locationInView:(AP_View*)view
{
    AP_NOT_IMPLEMENTED;
    return CGPointZero;
}

- (NSUInteger) numberOfTouches
{
    AP_NOT_IMPLEMENTED;
    return 0;
}

@end

@implementation AP_TapGestureRecognizer
@end

@implementation AP_LongPressGestureRecognizer
@end

@implementation AP_PinchGestureRecognizer
@end

@implementation AP_PanGestureRecognizer

- (CGPoint) velocityInView:(AP_View *)view
{
    AP_NOT_IMPLEMENTED;
    return CGPointZero;
}

- (CGPoint) translationInView:(AP_View*)view
{
    AP_NOT_IMPLEMENTED;
    return CGPointZero;
}

@end
