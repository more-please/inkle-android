#import "AP_Responder.h"

@implementation AP_Responder

- (AP_Responder*) nextResponder
{
    return nil;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event
{
    AP_Responder* next = self.nextResponder;
    if (next) {
        [next touchesBegan:touches withEvent:event];
    }
}

- (void) touchesCancelled:(NSSet*)touches withEvent:(AP_Event*)event
{
    AP_Responder* next = self.nextResponder;
    if (next) {
        [next touchesCancelled:touches withEvent:event];
    }
}

- (void) touchesEnded:(NSSet*)touches withEvent:(AP_Event*)event
{
    AP_Responder* next = self.nextResponder;
    if (next) {
        [next touchesEnded:touches withEvent:event];
    }
}

- (void) touchesMoved:(NSSet*)touches withEvent:(AP_Event*)event
{
    AP_Responder* next = self.nextResponder;
    if (next) {
        [next touchesMoved:touches withEvent:event];
    }
}

- (BOOL) handleAndroidBackButton
{
    return NO;
}

- (BOOL) handleMouseWheelX:(float)x Y:(float)y mousePos:(CGPoint)pos
{
    return [self handleMouseWheelX:x Y:y];
}

- (BOOL) handleMouseWheelX:(float)x Y:(float)y
{
    return NO;
}

- (BOOL) handleKeyDown:(int)key repeat:(BOOL)repeat shift:(BOOL)shift
{
    return [self handleKeyDown:key];
}

- (BOOL) handleKeyDown:(int)key
{
    return NO;
}

- (BOOL) handleKeyUp:(int)key
{
    return NO;
}

- (BOOL) dispatchEvent:(EventHandlerBlock)handler
{
    return handler(self);
}

@end
