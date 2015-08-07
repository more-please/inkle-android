#import "PFObject.h"

#import <UIKit/UIApplication.h>

#import "GlueCommon.h"

@implementation PFObject

- (instancetype) initWithObj:(void*)obj
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
#ifdef ANDROID
    jobject obj = [[UIApplication sharedApplication] parseNewObject:className];
    return [[PFObject alloc] initWithObj:obj];
#else
    GLUE_NOT_IMPLEMENTED;
    return nil;
#endif
}

+ (instancetype) objectWithoutDataWithClassName:(NSString*)className objectId:(NSString*)objectId
{
#ifdef ANDROID
    jobject obj = [[UIApplication sharedApplication] parseNewObject:className objectId:objectId];
    return [[PFObject alloc] initWithObj:obj];
#else
    GLUE_NOT_IMPLEMENTED;
    return nil;
#endif
}

- (void) setObject:(id)object forKey:(NSString*)key
{
    if (!object) {
        NSLog(@"*** Tried to set null value for key: %@", key);
        return;
    }
#ifdef ANDROID
    [[UIApplication sharedApplication] parseObject:_jobj addKey:key value:object];
#else
    GLUE_NOT_IMPLEMENTED;
#endif
}

- (void) saveInBackground
{
    [self saveInBackgroundWithBlock:nil];
}

- (void) saveInBackgroundWithBlock:(PFBooleanResultBlock)block
{
#ifdef ANDROID
    [[UIApplication sharedApplication] parseObject:_jobj saveWithBlock:block];
#else
    GLUE_NOT_IMPLEMENTED;
#endif
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
#ifdef ANDROID
    [[UIApplication sharedApplication] parseObject:_jobj refreshWithBlock:block];
#else
    GLUE_NOT_IMPLEMENTED;
#endif
}

- (void) fetchInBackgroundWithBlock:(PFObjectResultBlock)block
{
#ifdef ANDROID
    [[UIApplication sharedApplication] parseObject:_jobj fetchWithBlock:block];
#else
    GLUE_NOT_IMPLEMENTED;
#endif
}

- (void) removeObjectForKey:(NSString*)key
{
#ifdef ANDROID
    [[UIApplication sharedApplication] parseObject:_jobj removeKey:key];
#else
    GLUE_NOT_IMPLEMENTED;
#endif
}

- (void) saveEventually:(PFBooleanResultBlock)block
{
#ifdef ANDROID
    [[UIApplication sharedApplication] parseObject:_jobj saveEventuallyWithBlock:block];
#else
    GLUE_NOT_IMPLEMENTED;
#endif
}

- (NSString*) objectId
{
#ifdef ANDROID
    return [[UIApplication sharedApplication] parseObjectId:_jobj];
#else
    GLUE_NOT_IMPLEMENTED;
    return nil;
#endif
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
