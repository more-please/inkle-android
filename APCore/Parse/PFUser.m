#import "PFUser.h"

#import <UIKit/UIApplication.h>

#import "GlueCommon.h"

@implementation PFUser

+ (void) enableAutomaticUser
{
    [[UIApplication sharedApplication] parseEnableAutomaticUser];
}

+ (instancetype) currentUser
{
    jobject obj = [UIApplication sharedApplication].parseCurrentUser;
    return [[PFUser alloc] initWithObj:obj];
}

@end
