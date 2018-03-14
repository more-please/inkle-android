#import "PFUser.h"

#import <UIKit/UIApplication.h>

#import "GlueCommon.h"

@implementation PFUser

+ (void) enableAutomaticUser
{
#ifdef ANDROID
    [[UIApplication sharedApplication] parseEnableAutomaticUser];
#else
    GLUE_NOT_IMPLEMENTED;
#endif
}

+ (instancetype) currentUser
{
#ifdef ANDROID
    jobject obj = [UIApplication sharedApplication].parseCurrentUser;
    return [[PFUser alloc] initWithObj:obj];
#else
    GLUE_NOT_IMPLEMENTED;
    return nil;
#endif
}

@end
