#import "AP_StrongCache.h"

#import "AP_Animation.h"
#import "AP_Check.h"

@interface AP_StrongCache_Entry : NSObject
@property (nonatomic,strong) id key;
@property (nonatomic,strong) id value;
@property (nonatomic) NSTimeInterval timestamp;
@end

@implementation AP_StrongCache_Entry
@end

@implementation AP_StrongCache {
    NSMutableDictionary* _dict;
}

- (instancetype) initWithSize:(int)size
{
    self = [super init];
    if (self) {
        _cacheSize = size;
        _dict = [NSMutableDictionary dictionary];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarning:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) didReceiveMemoryWarning:(NSNotification*)notification
{
    [_dict removeAllObjects];
}

- (instancetype) init
{
    return [self initWithSize:5];
}

- (void) setCacheSize:(int)size
{
    _cacheSize = size;
    while (_dict.count > _cacheSize) {
        [self deleteOldestItem];
    }
}

- (id) get:(id)key withLoader:(id (^)(void))loader
{
    AP_StrongCache_Entry* entry = [_dict objectForKey:key];
    if (!entry) {
        while (_dict.count >= _cacheSize) {
            [self deleteOldestItem];
        }
        id result = loader();
        AP_CHECK(result, return nil);
        entry = [[AP_StrongCache_Entry alloc] init];
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
    AP_StrongCache_Entry* oldest = nil;
    for (NSString* key in _dict) {
        AP_StrongCache_Entry* entry = [_dict objectForKey:key];
        if (!oldest || entry.timestamp < oldest.timestamp) {
            oldest = entry;
        }
    }
    AP_CHECK(oldest || _dict.count == 0, abort());
//    NSLog(@"*** Pruning cache entry %@: %@", oldest.key, oldest.value);
    [_dict removeObjectForKey:oldest.key];
}

@end
