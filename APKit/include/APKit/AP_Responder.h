#pragma once

#import <Foundation/Foundation.h>

#import "AP_Event.h"

@interface AP_Responder : NSObject

- (AP_Responder*) nextResponder;

- (BOOL)canBecomeFirstResponder;    // default is NO
- (BOOL)becomeFirstResponder;

- (BOOL)canResignFirstResponder;    // default is YES
- (BOOL)resignFirstResponder;

- (BOOL)isFirstResponder;

- (void)touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event;
- (void)touchesMoved:(NSSet*)touches withEvent:(AP_Event*)event;
- (void)touchesEnded:(NSSet*)touches withEvent:(AP_Event*)event;
- (void)touchesCancelled:(NSSet*)touches withEvent:(AP_Event*)event;

@end
