#pragma once

#import <Foundation/Foundation.h>

#import "AP_View.h"

#ifdef ANDROID
typedef enum UITouchPhase {
    UITouchPhaseBegan,             // whenever a finger touches the surface.
    UITouchPhaseMoved,             // whenever a finger moves on the surface.
    UITouchPhaseStationary,        // whenever a finger is touching the surface but hasn't moved since the previous event.
    UITouchPhaseEnded,             // whenever a finger leaves the surface.
    UITouchPhaseCancelled,         // whenever a touch doesn't end but we need to stop tracking (e.g. putting device to face)
} UITouchPhase;
#endif

@interface AP_Touch : NSObject

- (CGPoint) initialLocationInView:(AP_View*)view;
- (CGPoint) locationInView:(AP_View*)view;

@property (nonatomic) UITouchPhase phase;
@property (nonatomic,assign) CGPoint initialWindowPos;
@property (nonatomic,assign) CGPoint windowPos;

+ (AP_Touch*) touchWithWindowPos:(CGPoint)pos;

@end

#ifdef ANDROID

// On Android, UITouch is a thin wrapper around an Android motion event.
// It holds a direct reference to an AP_Touch object.
@interface UITouch : NSObject

@property (nonatomic,strong) AP_Touch* android;
@property (nonatomic,assign) CGPoint location;

- (CGPoint)locationInView:(UIView*)view;

@end

#else

// On iOS, the AP_Touch is an associated object.
@interface UITouch(AP)
@property (nonatomic) AP_Touch* android;
@end

#endif
