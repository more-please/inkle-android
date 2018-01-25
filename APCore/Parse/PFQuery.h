#pragma once

#import "PFCommon.h"

@interface PFQuery : NSObject

+ (PFQuery*) queryWithClassName:(NSString*)className;

- (void) whereKey:(NSString*)key equalTo:(id)object;
- (void) findObjectsInBackgroundWithBlock:(PFArrayResultBlock)block;

@end