#import "PFCloud.h"

#import <UIKit/UIApplication.h>

#import "GlueCommon.h"

@implementation PFCloud

+ (void)callFunctionInBackground:(NSString*)function withParameters:(NSDictionary*)parameters block:(PFIdResultBlock)block
{
    NSAssert(parameters.count == 0, @"Can't call Parse function with parameters!");
    [[UIApplication sharedApplication] parseCallFunction:function block:block];
}

@end
