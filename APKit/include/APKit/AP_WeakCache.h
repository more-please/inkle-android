#pragma once

#import <Foundation/Foundation.h>

// A cache that holds weak references to its values.
// This is useful for ensuring that we only create one instance
// of named objects. It's *not* useful for speculatively caching
// data that might be needed later -- use AP_StrongCache for that.
@interface AP_WeakCache : NSObject

- (id) get:(id)key withLoader:(id(^)(void))block;

@end
