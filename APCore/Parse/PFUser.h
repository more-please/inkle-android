#pragma once

#import "PFObject.h"

@interface PFUser : PFObject

+ (void) enableAutomaticUser;

+ (instancetype) currentUser;

@end
