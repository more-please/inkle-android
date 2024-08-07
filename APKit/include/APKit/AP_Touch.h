#pragma once

#import <Foundation/Foundation.h>

#import "AP_View.h"

typedef enum UITouchPhase {
    UITouchPhaseBegan,             // whenever a finger touches the surface.
    UITouchPhaseMoved,             // whenever a finger moves on the surface.
    UITouchPhaseStationary,        // whenever a finger is touching the surface but hasn't moved since the previous event.
    UITouchPhaseEnded,             // whenever a finger leaves the surface.
    UITouchPhaseCancelled,         // whenever a touch doesn't end but we need to stop tracking (e.g. putting device to face)
} UITouchPhase;

@interface AP_Touch : NSObject

- (CGPoint) locationInView:(AP_View*)view;

@property(nonatomic,readonly,retain) AP_View* view;
@property (nonatomic) UITouchPhase phase;
@property (nonatomic,assign) CGPoint windowPos;

+ (AP_Touch*) touchWithWindowPos:(CGPoint)pos;

@end

@interface Real_UITouch : NSObject

@property (nonatomic,strong) AP_Touch* android;
@property (nonatomic,assign) CGPoint location;

- (CGPoint)locationInView:(UIView*)view;

@end
