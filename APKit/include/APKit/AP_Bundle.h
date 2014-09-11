#pragma once

#import <Foundation/Foundation.h>

#import "AP_Application.h"

extern const NSString* kCFBundleVersionKey;

// Wrapper for NSBundle. Also allows resource to be loaded from external .pak files.
// We use this on Android to manage extension files.
@interface AP_Bundle : NSObject

// Looks for the given resource in the .pak file(s), if any, then the main bundle.
+ (NSData*) dataForResource:(NSString *)name ofType:(NSString *)ext;

+ (AP_Bundle*) mainBundle;

// Like pathsForResources, but returns the bundle-relative resource name.
- (NSArray*) namesForResourcesOfType:(NSString*)ext inDirectory:(NSString*)dir;

- (NSDictionary*) infoDictionary;
- (id) objectForInfoDictionaryKey:(NSString*)key;

@end
