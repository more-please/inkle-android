#import "AP_Touch.h"

#import <objc/runtime.h>
#import "AP_View.h"

#ifndef ANDROID
@implementation UITouch(AP)
- (void) setAndroid:(AP_Touch*)t
{
    objc_setAssociatedObject(self, @selector(android), t, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (AP_Touch*) android
{
    return objc_getAssociatedObject(self, @selector(android));
}
@end
#endif

@implementation AP_Touch

- (CGPoint) locationInView:(AP_View*)view
{
    return [view convertPoint:_windowPos fromView:nil];
}

+ (AP_Touch*) touchWithWindowPos:(CGPoint)windowPos
{
    AP_Touch* result = [[AP_Touch alloc] init];
    result->_windowPos = windowPos;
    return result;
}

@end
