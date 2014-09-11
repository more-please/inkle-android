#pragma once

#import "PFCommon.h"

@interface PFObject : NSObject

+ (instancetype) objectWithClassName:(NSString*)className;

- (id) objectForKey:(NSString*)key;
- (void) addUniqueObject:(id)object forKey:(NSString*)key;
- (void) setObject:(id)object forKey:(NSString*)key;
- (void) saveInBackground;
- (void) saveInBackgroundWithBlock:(PFBooleanResultBlock)block;

- (id)objectForKeyedSubscript:(NSString*)key;
- (void)setObject:(id)object forKeyedSubscript:(NSString*)key;

@end