#import "GAIDictionaryBuilder.h"

#import "GlueCommon.h"

@implementation GAIDictionaryBuilder {
    void* _obj;
}

+ (GAIDictionaryBuilder *)createEventWithCategory:(NSString *)category
                                           action:(NSString *)action
                                            label:(NSString *)label
                                            value:(NSNumber *)value
{
#ifdef ANDROID
    GAIDictionaryBuilder* builder = [[GAIDictionaryBuilder alloc] init];
    builder->_obj = [[UIApplication sharedApplication] gaiEventWithCategory:category action:action label:label value:value];
    return builder;
#else
    GLUE_NOT_IMPLEMENTED;
    return nil;
#endif
}

- (void*) build
{
    return _obj;
}

@end
