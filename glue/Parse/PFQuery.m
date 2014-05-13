#import "PFQuery.h"

#import <UIKit/UIApplication.h>

#import "GlueCommon.h"

@implementation PFQuery {
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

+ (PFQuery*) queryWithClassName:(NSString*)className
{
    jobject obj = [[UIApplication sharedApplication] parseNewQuery:className];
    return [[PFQuery alloc] initWithObj:obj];
}

- (void) whereKey:(NSString*)key equalTo:(id)object
{
    [[UIApplication sharedApplication] parseQuery:_obj whereKey:key equalTo:object];
}

- (void) findObjectsInBackgroundWithBlock:(PFArrayResultBlock)block
{
    [[UIApplication sharedApplication] parseQuery:_obj findWithBlock:block];
}

@end
