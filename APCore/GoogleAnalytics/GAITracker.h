#pragma once

#import <Foundation/Foundation.h>

@protocol GAITracker<NSObject>

- (void) set:(NSString*)parameterName value:(NSString*)value;

- (void) send:(NSDictionary*)parameters;

// Iain additions

// Send this in the next message only
- (void) setOnce:(NSString*)parameterName value:(NSString*)value;

@end

@interface AP_GAITracker : NSObject<GAITracker>

- (instancetype) initWithTrackingId:(NSString*)trackingId;

@end
