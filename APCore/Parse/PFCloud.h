#pragma once

#import "PFCommon.h"

@interface PFCloud : NSObject

+ (void) callFunctionInBackground:(NSString*)function withParameters:(NSDictionary*)parameters block:(PFIdResultBlock)block;

@end