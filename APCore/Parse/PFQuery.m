#import "PFQuery.h"

#import <UIKit/UIApplication.h>

#import "GlueCommon.h"

@implementation PFQuery {
    void* _obj;
}

- (id) initWithObj:(void*)obj
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

+ (PFQuery*) queryWithClassName:(NSString*)className
{
#ifdef ANDROID
    jobject obj = [[UIApplication sharedApplication] parseNewQuery:className];
    return [[PFQuery alloc] initWithObj:obj];
#else
    GLUE_NOT_IMPLEMENTED;
    return nil;
#endif
}

- (void) whereKey:(NSString*)key equalTo:(id)object
{
#ifdef ANDROID
    [[UIApplication sharedApplication] parseQuery:_obj whereKey:key equalTo:object];
#else
    GLUE_NOT_IMPLEMENTED;
#endif
}

- (void) findObjectsInBackgroundWithBlock:(PFArrayResultBlock)block
{
#ifdef ANDROID
    [[UIApplication sharedApplication] parseQuery:_obj findWithBlock:block];
#else
    GLUE_NOT_IMPLEMENTED;
#endif
}

@end
