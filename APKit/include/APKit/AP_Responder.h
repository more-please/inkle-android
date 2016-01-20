#pragma once

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

#import "AP_Event.h"

@interface AP_Responder : NSObject

- (void)touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event;
- (void)touchesMoved:(NSSet*)touches withEvent:(AP_Event*)event;
- (void)touchesEnded:(NSSet*)touches withEvent:(AP_Event*)event;
- (void)touchesCancelled:(NSSet*)touches withEvent:(AP_Event*)event;

// ----------------------------------------------------------------------
// Keyboard commands and other shortcuts. Not handled like real iOS --
// dispatch is via the view hierarchy, not the responder chain.

// Override these. Call super.
- (BOOL) handleMouseWheelX:(float)x Y:(float)y mousePos:(CGPoint)pos; // Calls the method below by default
- (BOOL) handleMouseWheelX:(float)x Y:(float)y;
- (BOOL) handleKeyDown:(int)key repeat:(BOOL)repeat shift:(BOOL)shift; // Calls the method below by default
- (BOOL) handleKeyDown:(int)key;
- (BOOL) handleKeyUp:(int)key;
- (BOOL) handleAndroidBackButton;
- (BOOL) handleControlKey:(int)key;

// Block that calls one of the above methods.
typedef BOOL (^EventHandlerBlock)(AP_Responder*);

// Default just calls handler(self).
// Subclasses can override to implement a different response chain.
- (BOOL) dispatchEvent:(EventHandlerBlock)handler;

@end
