#pragma once

#import <Foundation/Foundation.h>

@interface AP_FPSCounter : NSObject

- (void) tick; // Call this once per frame.
- (void) reset; // Call this to reset the counter.

@property (readonly) double fps; // Returns the current ticks per second (smoothed).
@property (readonly) unsigned count; // Number of ticks since startup.

@end
