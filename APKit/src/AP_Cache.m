#import "AP_Cache.h"

#import "AP_Animation.h"
#import "AP_Check.h"

@interface AP_Cache_Entry : NSObject
@property (nonatomic,strong) id key;
@property (nonatomic,weak) id value;
@end

@implementation AP_Cache_Entry
@end

@implementation AP_Cache {
    NSMutableDictionary* _dict;
}

- (AP_Cache*) init
{
    self = [super init];
    if (self) {
        _dict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id) get:(id)key withLoader:(id (^)(void))loader
{
    AP_Cache_Entry* entry = [_dict objectForKey:key];
    id result = entry.value;
    if (!result) {
        result = loader();
        AP_CHECK(result, return nil);
        entry = [[AP_Cache_Entry alloc] init];
        entry.key = key;
        entry.value = result;
        [_dict setObject:entry forKey:key];
    }
    return result;
}

@end
