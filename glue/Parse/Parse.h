#pragma once

#import "PFCloud.h"
#import "PFInstallation.h"
#import "PFObject.h"
#import "PFQuery.h"

@interface Parse : NSObject

+ (void) setApplicationId:(NSString*)applicationId clientKey:(NSString*)clientKey;
+ (NSString*) getApplicationId;
+ (NSString*) getClientKey;

//+ (void) offlineMessagesEnabled:(BOOL)enabled;
//+ (void) errorMessagesEnabled:(BOOL)enabled;

@end
