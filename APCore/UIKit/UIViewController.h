#pragma once

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#import "UIEvent.h"

@class UIView;

@interface Real_UIViewController : NSObject

@property(nonatomic,assign,getter=isPaused) BOOL paused;
@property(nonatomic,readonly,strong) UIView* view; // Not actually used for anything (yet)

- (void) draw;

- (void) touchesBegan:(NSSet*)touches withEvent:(Real_UIEvent*)event;
- (void) touchesCancelled:(NSSet*)touches withEvent:(Real_UIEvent*)event;
- (void) touchesEnded:(NSSet*)touches withEvent:(Real_UIEvent*)event;
- (void) touchesMoved:(NSSet*)touches withEvent:(Real_UIEvent*)event;
- (void) resetTouches;

// Android addition, so we can throttle down when we're not drawing
@property(nonatomic) int idleFrameCount;

@end
