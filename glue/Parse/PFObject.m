#import "PFObject.h"

#import "GlueCommon.h"

@implementation PFObject

+ (instancetype) objectWithClassName:(NSString*)className
{
    GLUE_NOT_IMPLEMENTED;
    return nil;
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

- (void) setObject:(id)object forKey:(NSString*)key
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) saveInBackground
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) saveInBackgroundWithBlock:(PFBooleanResultBlock)block
{
    GLUE_NOT_IMPLEMENTED;
}

@end
