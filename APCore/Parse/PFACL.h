#pragma once

#import "PFCommon.h"

@interface PFACL : NSObject

- (void) setPublicReadAccess:(BOOL)allowed;

+ (PFACL*) ACL;

+ (void) setDefaultACL:(PFACL*)acl withAccessForCurrentUser:(BOOL)currentUserAccess;

@end
