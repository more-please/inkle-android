#pragma once

#import <Foundation/Foundation.h>

#import "GAITracker.h"

@interface GAI : NSObject

+ (GAI*) sharedInstance;

- (id<GAITracker>)trackerWithTrackingId:(NSString *)trackingId;
- (id<GAITracker>)defaultTracker;

// Iain additions
- (void) send:(NSDictionary*)params;

@end
