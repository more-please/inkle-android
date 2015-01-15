#import "AP_WeakCache.h"

#import "AP_Animation.h"
#import "AP_Check.h"

@interface AP_WeakCache_Entry : NSObject
@property (nonatomic,strong) id key;
@property (nonatomic,weak) id value;
@end

@implementation AP_WeakCache_Entry
@end

@implementation AP_WeakCache {
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

- (id) get:(id)key withLoader:(id (^)(void))loader
{
    AP_WeakCache_Entry* entry = [_dict objectForKey:key];
    id result = entry.value;
    if (!result) {
        result = loader();
        if (!result) {
            return nil;
        }
        entry = [[AP_WeakCache_Entry alloc] init];
        entry.key = key;
        entry.value = result;
        [_dict setObject:entry forKey:key];
    }
    return result;
}

@end
