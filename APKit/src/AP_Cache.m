#import "AP_Cache.h"

#import "AP_Animation.h"
#import "AP_Check.h"

@interface AP_Cache_Entry : NSObject
@property (nonatomic,strong) id key;
@property (nonatomic,strong) id value;
@property (nonatomic) NSTimeInterval timestamp;
@end

@implementation AP_Cache_Entry
@end

@implementation AP_Cache {
    NSMutableDictionary* _dict;
}

- (AP_Cache*) initWithSize:(int)size
{
    self = [super init];
    if (self) {
        _size = size;
        _dict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (AP_Cache*) init
{
    return [self initWithSize:5];
}

- (void) setSize:(int)size
{
    _size = size;
    while (_dict.count > _size) {
        [self deleteOldestItem];
    }
}

- (id) get:(id)key withLoader:(id (^)(void))loader
{
    AP_Cache_Entry* entry = [_dict objectForKey:key];
    if (!entry) {
        while (_dict.count >= _size) {
            [self deleteOldestItem];
        }
        id result = loader();
        AP_CHECK(result, return nil);
        entry = [[AP_Cache_Entry alloc] init];
        entry.key = key;
        entry.value = result;
        [_dict setObject:entry forKey:key];
    }
    entry.timestamp = CACurrentMediaTime();
    AP_CHECK(entry.value, return nil);
    return entry.value;
}

- (void) deleteOldestItem
{
    AP_Cache_Entry* oldest = nil;
    for (NSString* key in _dict) {
        AP_Cache_Entry* entry = [_dict objectForKey:key];
        if (!oldest || entry.timestamp < oldest.timestamp) {
            oldest = entry;
        }
    }
    AP_CHECK(oldest || _dict.count == 0, abort());
//    NSLog(@"*** Pruning cache entry %@: %@", oldest.key, oldest.value);
    [_dict removeObjectForKey:oldest.key];
}

@end
