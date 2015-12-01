#pragma once

#import <Foundation/Foundation.h>

@interface NSObject (AP_PerformBlock)
- (void) performBlock:(void(^)())block;
- (void) performBlock:(void(^)())block afterDelay:(NSTimeInterval)delay;
- (void) performBlock:(void(^)())block onThread:(NSThread*)thread waitUntilDone:(BOOL)waitUntilDone;
@end
