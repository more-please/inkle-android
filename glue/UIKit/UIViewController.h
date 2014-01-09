#pragma once

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class UIEvent;
@class UIView;

@interface UIViewController : NSObject

@property(nonatomic,assign,getter=isPaused) BOOL paused;
@property(nonatomic,readonly,strong) UIView* view; // Not actually used for anything (yet)

- (void) draw;

// The "event" parameter isn't used in any of these methods yet.
- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event;
- (void) touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event;
- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event;
- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event;

@end
