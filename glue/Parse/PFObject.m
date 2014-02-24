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

@end
