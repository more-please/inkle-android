#pragma once

#import "PFCommon.h"
#import "PFObject.h"

@interface PFInstallation : PFObject

+ (instancetype) currentInstallation;

- (void) setDeviceTokenFromData:(NSData*)deviceTokenData;

@end