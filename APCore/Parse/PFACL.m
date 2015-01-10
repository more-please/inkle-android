#import "PFACL.h"

#import <UIKit/UIApplication.h>

#import "GlueCommon.h"

@implementation PFACL

- (void) setPublicReadAccess:(BOOL)allowed
{
    GLUE_NOT_IMPLEMENTED;
}

+ (PFACL*) ACL
{
    return [[PFACL alloc] init];
}

+ (void) setDefaultACL:(PFACL*)acl withAccessForCurrentUser:(BOOL)currentUserAccess
{
    GLUE_NOT_IMPLEMENTED;
}

@end
