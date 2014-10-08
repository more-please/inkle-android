#import "PFCloud.h"

#import <UIKit/UIApplication.h>

#import "GlueCommon.h"

@implementation PFCloud

+ (void)callFunctionInBackground:(NSString*)function withParameters:(NSDictionary*)parameters block:(PFIdResultBlock)block
{
    if (parameters.count) {
        GLUE_NOT_IMPLEMENTED;
        return;
    }
    [[UIApplication sharedApplication] parseCallFunction:function block:block];
}

@end
