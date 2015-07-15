#import "AP_Touch.h"

#import <objc/runtime.h>
#import "AP_View.h"

@implementation Real_UITouch

- (CGPoint)locationInView:(UIView*)view
{
    return _location;
}

@end

@implementation AP_Touch

- (CGPoint) locationInView:(AP_View*)view
{
    return [view convertPoint:_windowPos fromView:nil];
}

+ (AP_Touch*) touchWithWindowPos:(CGPoint)windowPos
{
    AP_Touch* result = [[AP_Touch alloc] init];
    result->_windowPos = windowPos;
    result->_phase = UITouchPhaseBegan;
    return result;
}

@end
