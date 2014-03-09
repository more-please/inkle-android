#import "GAIDictionaryBuilder.h"

#import "GlueCommon.h"

@implementation GAIDictionaryBuilder {
    jobject _obj;
}

+ (GAIDictionaryBuilder *)createEventWithCategory:(NSString *)category
                                           action:(NSString *)action
                                            label:(NSString *)label
                                            value:(NSNumber *)value
{
    GAIDictionaryBuilder* builder = [[GAIDictionaryBuilder alloc] init];
    builder->_obj = [[UIApplication sharedApplication] gaiEventWithCategory:category action:action label:label value:value];
    return builder;
}

- (jobject) build
{
    return _obj;
}

@end
