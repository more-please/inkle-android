#import "PFCloud.h"

#import <UIKit/UIApplication.h>

#import "GlueCommon.h"

@implementation PFCloud

+ (void)callFunctionInBackground:(NSString*)function withParameters:(NSDictionary*)parameters block:(PFIdResultBlock)block
{
    [[UIApplication sharedApplication] parseCallFunction:function parameters:parameters block:block];
}

@end
