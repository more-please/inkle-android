#pragma once

#import <Foundation/Foundation.h>

@interface AP_FPSCounter : NSObject

- (void) tick; // Call this once per frame.
- (void) reset; // Call this to reset the counter.

@property (nonatomic,readonly) double fps; // Returns the current ticks per second (smoothed).
@property (nonatomic,readonly) unsigned count; // Number of ticks since startup.
@property (nonatomic) double logInterval; // If non-zero, log FPS to console every N seconds.
@end
