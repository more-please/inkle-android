#import "AP_Cache.h"

#import "AP_Check.h"

// Should just be an NSMapTable, but Apportable doesn't have it...

@interface AP_Cache_Entry : NSObject
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

- (id) get:(NSString *)name withLoader:(id (^)(void))loader
{
    AP_Cache_Entry* entry = [_dict objectForKey:name];
    id result = entry ? entry.value : nil;
    if (!result) {
        result = loader();
        AP_CHECK(result, return nil);
        entry = [[AP_Cache_Entry alloc] init];
        entry.value = result;
        [_dict setObject:entry forKey:name];
    }
    return result;
}
@end
