#pragma once

@protocol GAITracker<NSObject>

- (void) set:(NSString*)parameterName value:(NSString*)value;

- (void) send:(NSDictionary*)parameters;

@end
