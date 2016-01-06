#pragma once

#import <Foundation/Foundation.h>

// A set that holds weak references to its values.
@interface AP_WeakSet : NSObject

@property (strong) NSSet* items;

- (void) addObject:(id)object;
- (void) removeObject:(id)object;

@end
