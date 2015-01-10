#import "GAITracker.h"

#import "GlueCommon.h"

@implementation AP_GAITracker {
    jobject _obj;
}

- (instancetype) initWithObj:(jobject)obj
{
    self = [super init];
    if (self) {
        _obj = obj;
    }
    return self;
}

- (void) set:(NSString*)parameterName value:(NSString*)value
{
    [[UIApplication sharedApplication] gaiTracker:_obj set:parameterName value:value];
}

- (void) send:(jobject)parameters
{
    [[UIApplication sharedApplication] gaiTracker:_obj send:parameters];
}

@end
