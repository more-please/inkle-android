#pragma once

#import <Foundation/Foundation.h>

#ifdef AP_REPLACE_UI

#import "AP_Event.h"

@interface AP_Responder : NSObject

- (AP_Responder*) nextResponder;

- (void)touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event;
- (void)touchesMoved:(NSSet*)touches withEvent:(AP_Event*)event;
- (void)touchesEnded:(NSSet*)touches withEvent:(AP_Event*)event;
- (void)touchesCancelled:(NSSet*)touches withEvent:(AP_Event*)event;

@end

#else
typedef UIResponder AP_Responder;
#endif
