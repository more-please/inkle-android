#pragma once

#import <Foundation/Foundation.h>

// A cache that holds strong references to its values.
// The "cacheSize" most recently access values are retained.
@interface AP_StrongCache : NSObject

@property(nonatomic) int cacheSize;

- (instancetype) initWithSize:(int)size;

- (id) get:(id)key withLoader:(id(^)(void))block;

@end
