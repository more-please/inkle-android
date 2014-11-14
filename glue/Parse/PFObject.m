#import "PFObject.h"

#import <UIKit/UIApplication.h>

#import "GlueCommon.h"

@implementation PFObject {
    jobject _obj;
}

- (id) initWithObj:(jobject)obj
{
    if (!obj) {
        return nil;
    }
    self = [super init];
    if (self) {
        _obj = obj;
    }
    return self;
}

+ (instancetype) objectWithClassName:(NSString*)className
{
    jobject obj = [[UIApplication sharedApplication] parseNewObject:className];
    return [[PFObject alloc] initWithObj:obj];
}

- (void) setObject:(id)object forKey:(NSString*)key
{
    [[UIApplication sharedApplication] parseObject:_obj addKey:key value:object];
}

- (void) saveInBackground
{
    [self saveInBackgroundWithBlock:nil];
}

- (void) saveInBackgroundWithBlock:(PFBooleanResultBlock)block
{
    [[UIApplication sharedApplication] parseObject:_obj saveWithBlock:block];
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
    GLUE_NOT_IMPLEMENTED;
}

- (void) fetchInBackgroundWithBlock:(PFObjectResultBlock)block
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) removeObjectForKey:(NSString*)key
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) saveEventually:(PFBooleanResultBlock)callback
{
    GLUE_NOT_IMPLEMENTED;
}

+ (instancetype) objectWithoutDataWithClassName:(NSString*)className objectId:(NSString*)objectId
{
    GLUE_NOT_IMPLEMENTED;
    return nil;
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
