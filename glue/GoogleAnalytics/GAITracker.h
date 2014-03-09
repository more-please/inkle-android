#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol GAITracker<NSObject>

- (void) set:(NSString*)parameterName value:(NSString*)value;

// On iOS the parameter is an NSDictionary, but on Android
// it's an opaque reference to a Java Map.
- (void) send:(jobject)parameters;

@end

@interface AP_GAITracker : NSObject<GAITracker>

- (instancetype) initWithObj:(jobject)obj;

@end