#pragma once

#import "PFAnalytics.h"
#import "PFCloud.h"
#import "PFInstallation.h"
#import "PFObject.h"
#import "PFQuery.h"
#import "PFUser.h"
#import "PFACL.h"

@interface Parse : NSObject

+ (void) setApplicationId:(NSString*)applicationId host:(NSString*)host;
+ (NSString*) getApplicationId;
+ (NSString*) getHost;

//+ (void) offlineMessagesEnabled:(BOOL)enabled;
//+ (void) errorMessagesEnabled:(BOOL)enabled;

@end
