#import "PFObject.h"

#import <UIKit/UIApplication.h>

#import "GlueCommon.h"

@implementation PFObject

- (instancetype) initWithObj:(jobject)obj
{
    if (!obj) {
        return nil;
    }
    self = [super init];
    if (self) {
        _jobj = obj;
    }
    return self;
}

+ (instancetype) objectWithClassName:(NSString*)className
{
    jobject obj = [[UIApplication sharedApplication] parseNewObject:className];
    return [[PFObject alloc] initWithObj:obj];
}

+ (instancetype) objectWithoutDataWithClassName:(NSString*)className objectId:(NSString*)objectId
{
    jobject obj = [[UIApplication sharedApplication] parseNewObject:className objectId:objectId];
    return [[PFObject alloc] initWithObj:obj];
}

- (void) setObject:(id)object forKey:(NSString*)key
{
    if (!object) {
        NSLog(@"*** Tried to set null value for key: %@", key);
        return;
    }
    [[UIApplication sharedApplication] parseObject:_jobj addKey:key value:object];
}

- (void) saveInBackground
{
    [self saveInBackgroundWithBlock:nil];
}

- (void) saveInBackgroundWithBlock:(PFBooleanResultBlock)block
{
    [[UIApplication sharedApplication] parseObject:_jobj saveWithBlock:block];
}

- (id) objectForKey:(NSString*)key
{
    GLUE_NOT_IMPLEMENTED;
    return nil;
}

- (void) addUniqueObject:(id)object forKey:(NSString*)key
{
    GLUE_NOT_IMPLEMENTED;
}

- (id) objectForKeyedSubscript:(NSString*)key
{
    return [self objectForKey:key];
}

- (void) setObject:(id)object forKeyedSubscript:(NSString*)key
{
    [self setObject:object forKey:key];
}

- (void) refreshInBackgroundWithBlock:(PFObjectResultBlock)block
{
    [[UIApplication sharedApplication] parseObject:_jobj refreshWithBlock:block];
}

- (void) fetchInBackgroundWithBlock:(PFObjectResultBlock)block
{
    [[UIApplication sharedApplication] parseObject:_jobj fetchWithBlock:block];
}

- (void) removeObjectForKey:(NSString*)key
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) saveEventually:(PFBooleanResultBlock)block
{
    [[UIApplication sharedApplication] parseObject:_jobj saveEventuallyWithBlock:block];
}

- (NSString*) objectId
{
    return [[UIApplication sharedApplication] parseObjectId:_jobj];
}

@end

@implementation NSDictionary (PFObject)

- (NSString*) objectId
{
    return self[@"__parse_objectId"];
}

- (NSDate*) updatedAt
{
    NSNumber* n = self[@"__parse_updatedAt"];
    return [NSDate dateWithTimeIntervalSince1970:n.doubleValue];
}

@end
