#import "GAIDictionaryBuilder.h"

#import "GAIFields.h"

@implementation GAIDictionaryBuilder {
    NSMutableDictionary* _dict;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        _dict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void) setObject:(id)value forKeyedSubscript:(NSString*)key
{
    _dict[key] = value;
}

+ (GAIDictionaryBuilder *)createEventWithCategory:(NSString *)category
                                           action:(NSString *)action
                                            label:(NSString *)label
                                            value:(NSNumber *)value
{
    GAIDictionaryBuilder* result = [[GAIDictionaryBuilder alloc] init];
    result[kGAIHitType] = @"event";
    if (category) {
        result[kGAIEventCategory] = category;
    }
    if (action) {
        result[kGAIEventAction] = action;
    }
    if (label) {
        result[kGAIEventLabel] = label;
    }
    if (value) {
        result[kGAIEventValue] = value;
    }
    return result;
}

- (NSDictionary*) build
{
    return [NSDictionary dictionaryWithDictionary:_dict];
}

@end
