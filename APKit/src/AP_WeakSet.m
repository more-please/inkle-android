#import "AP_WeakSet.h"

#import "AP_Check.h"

@interface AP_WeakSet_Entry : NSObject
@property (nonatomic,weak) id value;
+ (AP_WeakSet_Entry*) entryWithObject:(id)object;
@end

@implementation AP_WeakSet_Entry
+ (AP_WeakSet_Entry*) entryWithObject:(id)object
{
    AP_WeakSet_Entry* result = [[AP_WeakSet_Entry alloc] init];
    result->_value = object;
    return result;
}
@end

@implementation AP_WeakSet {
    NSMutableArray* _array;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        _array = [NSMutableArray array];
    }
    return self;
}

- (void) addObject:(id)object
{
    [_array addObject:[AP_WeakSet_Entry entryWithObject:object]];
}

- (void) removeObject:(id)object
{
    int n = _array.count;
    for (int i = 0; i < n; ++i) {
        AP_WeakSet_Entry* e = _array[i];
        if (e.value == object) {
            [_array removeObjectAtIndex:i];
            return;
        }
    }
}

- (NSSet*) items
{
    NSMutableSet* result = [NSMutableSet set];
    BOOL itemRemoved = NO;
    for (AP_WeakSet_Entry* e in _array) {
        id object = e.value;
        if (object) {
            [result addObject:object];
        } else {
            itemRemoved = YES;
        }
    }
    if (itemRemoved) {
        [self setItems:result];
    }
    return result;
}

- (void) setItems:(NSSet*)items
{
    _array = [NSMutableArray array];
    for (id object in items) {
        [_array addObject:[AP_WeakSet_Entry entryWithObject:object]];
    }
}

@end
