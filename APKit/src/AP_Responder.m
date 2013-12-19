#import "AP_Responder.h"

@implementation AP_Responder

- (AP_Responder*) nextResponder
{
    return nil;
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

@end
