#import "AP_Bundle.h"

#import "AP_Check.h"
#import "NSDictionary+AP_InitWithData.h"

@implementation AP_Bundle {
    NSMutableArray* _paks;
    NSDictionary* _info;
}

static AP_Bundle* g_Bundle;

+ (void)initialize
{
    static BOOL initialized = NO;
    if (!initialized)
    {
        initialized = YES;
        g_Bundle = [[AP_Bundle alloc] init];
    }
}

- (AP_Bundle*) init
{
    AP_CHECK(!g_Bundle, return nil);

    self = [super init];
    if (self) {
        _paks = [NSMutableArray array];
    }
    return self;
}

- (void) dealloc
{
    AP_CHECK(g_Bundle == self, return);
    g_Bundle = nil;
}

+ (void) addPak:(AP_PakReader *)pak
{
    [g_Bundle->_paks addObject:pak];
}

+ (NSData*) dataForResource:(NSString *)name ofType:(NSString *)ext
{
    NSLog(@"*** dataForResource:%@ ofType:%@", name, ext);

    NSString* fullName = name;
    if (ext) {
        if (![ext hasPrefix:@"."]) {
            ext = [@"." stringByAppendingString:ext];
        }
        fullName = [name stringByAppendingString:ext];
    }

    // Try loading from the .pak file
    for (AP_PakReader* pak in g_Bundle->_paks) {
        NSData* data = [pak getFile:fullName];
        if (data) {
            return data;
        }
    }

#ifdef ANDROID
    // Try loading an Android asset
    return [[AP_Application sharedApplication] getResource:fullName];
#else
    NSLog(@"*** Failed to load resource:%@ ofType:%@", name, ext);
    return nil;
#endif
}

#ifdef ANDROID
+ (AP_Bundle*) mainBundle
{
    return g_Bundle;
}
#else
+ (NSBundle*) mainBundle
{
    return [NSBundle mainBundle];
}
#endif

#ifdef ANDROID
- (NSArray*) namesForResourcesOfType:(NSString *)ext inDirectory:(NSString *)dir
{
    return [[AP_Application sharedApplication] namesForResourcesOfType:ext inDirectory:dir];
}
#endif

- (NSDictionary*) infoDictionary
{
    if (!_info) {
        NSLog(@"Loading info dictionary...");
        NSData* data = [AP_Bundle dataForResource:@"Info" ofType:@"plist"];
        _info = [NSDictionary dictionaryWithPlistData:data];
        AP_CHECK(_info, return nil);
        NSLog(@"Loading info dictionary... Done.");
    }
    return _info;
}

- (id) objectForInfoDictionaryKey:(NSString*)key
{
    id result = [[self infoDictionary] objectForKey:key];
    NSLog(@"objectForInfoDictionaryKey:%@ -> %@", key, result);
    return result;
}

@end
