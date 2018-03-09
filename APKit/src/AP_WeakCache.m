#import "AP_WeakCache.h"

#import "AP_Animation.h"
#import "AP_Check.h"
#import "AP_Utils.h"

#import <PAK/PAK.h>

@interface AP_WeakCache_Entry : NSObject
@property (nonatomic,strong) id key;
@property (nonatomic,strong) id value;
@end

@implementation AP_WeakCache_Entry {
    id _value;
    double _atime;
}

- (id) value
{
    _atime = AP_TimeInSeconds();
    return _value;
}

- (void) setValue:(id)v
{
    _atime = AP_TimeInSeconds();
    _value = v;
}

- (void) maybeExpire
{
    double now = AP_TimeInSeconds();
    double age = now - _atime;
    if (_value && (age > 600)) {
        NSLog(@"Expiring cache entry: %@", _key);
        _value = nil;
    }
}

@end

@implementation AP_WeakCache {
    NSMutableDictionary* _dict;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        _dict = [NSMutableDictionary dictionary];

        [[NSNotificationCenter defaultCenter]
            addObserver:self
            selector:@selector(searchPathChanged:)
            name:PAK_SearchPathChangedNotification
            object:nil
        ];
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) searchPathChanged:(NSNotification*)notification
{
    [_dict removeAllObjects];
}

- (id) get:(id)key withLoader:(id (^)(void))loader
{
    AP_WeakCache_Entry* entry = [_dict objectForKey:key];
    id result = entry.value;
    if (!result) {
        // Delete any items that haven't been accessed recently
        for (id k in _dict) {
            AP_WeakCache_Entry* e = [_dict objectForKey:k];
            [e maybeExpire];
        }

        // Create the new item.
        result = loader();
        if (!result) {
            return nil;
        }

        // Add it to the cache.
        entry = [[AP_WeakCache_Entry alloc] init];
        entry.key = key;
        entry.value = result;
        [_dict setObject:entry forKey:key];
    }
    return result;
}

@end
