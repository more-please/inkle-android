#import "GAITracker.h"

#import "GlueCommon.h"

@implementation AP_GAITracker {
    void* _obj;
}

- (instancetype) initWithObj:(void*)obj
{
    self = [super init];
    if (self) {
        _obj = obj;
    }
    return self;
}

- (void) set:(NSString*)parameterName value:(NSString*)value
{
#ifdef ANDROID
    [[UIApplication sharedApplication] gaiTracker:_obj set:parameterName value:value];
#else
    GLUE_NOT_IMPLEMENTED;
#endif
}

- (void) send:(void*)parameters
{
#ifdef ANDROID
    [[UIApplication sharedApplication] gaiTracker:_obj send:parameters];
#else
    GLUE_NOT_IMPLEMENTED;
#endif
}

@end
