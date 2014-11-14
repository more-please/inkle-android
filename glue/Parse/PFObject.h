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

// To be implemented...
- (void) refreshInBackgroundWithBlock:(PFObjectResultBlock)block;
- (void) fetchInBackgroundWithBlock:(PFObjectResultBlock)block;
- (void) removeObjectForKey:(NSString*)key;
- (void) saveEventually:(PFBooleanResultBlock)callback;

@property (nonatomic,strong) NSString* objectId;
@property (nonatomic,strong,readonly) NSDate* updatedAt;

+ (instancetype) objectWithoutDataWithClassName:(NSString*)className objectId:(NSString*)objectId;

@end

// Bit of a hack here: some Parse RPCs return PFObjects, but when they pass between
// Java and Objective-C they get flattened into dictionaries. We'll therefore encode
// the 'objectId' and 'updatedAt' properties as secret dictionary entries.

@interface NSDictionary (PFObject)

- (NSString*) objectId;
- (NSDate*) updatedAt;

@end
