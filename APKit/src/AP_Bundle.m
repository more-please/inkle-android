#import "AP_Bundle.h"

#import "AP_Check.h"
#import "NSDictionary+AP_InitWithData.h"

#ifdef ANDROID
#import <PAK/PAK.h>
#endif

#ifdef ANDROID
const NSString* kCFBundleVersionKey = @"CFBundleVersion";
#endif

@implementation AP_Bundle {
    NSDictionary* _info;
}

static AP_Bundle* g_Bundle;

+ (void)initialize
{
    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        g_Bundle = [[AP_Bundle alloc] init];
    }
}

- (void) dealloc
{
    AP_CHECK(g_Bundle == self, return);
    g_Bundle = nil;
}

+ (NSData*) dataForResource:(NSString *)name ofType:(NSString *)ext
{
    NSString* fullName = name;
    if (ext) {
        fullName = [fullName stringByAppendingPathExtension:ext];
    }
    // Always use 'json', not 'minjson'
    if ([fullName.pathExtension isEqualToString:@"minjson"]) {
        fullName = [fullName stringByDeletingPathExtension];
        fullName = [fullName stringByAppendingPathExtension:@"json"];
    }
//     DLOG(@"Loading resource: %@", fullName);
#ifdef ANDROID
    PAK_Item* item = [PAK_Search item:fullName];
    if (item) {
        return item.data;
    }
#endif
//     DLOG(@"*** Failed to load resource:%@ ofType:%@", name, ext);
    return nil;
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
+ (NSArray*) namesForResourcesOfType:(NSString *)ext inDirectory:(NSString *)dir
{
    NSMutableArray* results = [NSMutableArray array];
    for (NSString* name in [PAK_Search names]) {
        if ([name hasPrefix:dir] && [name hasSuffix:ext]) {
            [results addObject:name];
        }
    }
    return [NSArray arrayWithArray:results];
}
#endif

- (NSDictionary*) infoDictionary
{
    if (!_info) {
        DLOG(@"Loading info dictionary...");
        NSData* data = [AP_Bundle dataForResource:@"Info" ofType:@"plist"];
        _info = [NSDictionary dictionaryWithPlistData:data];
        AP_CHECK(_info, return nil);
        DLOG(@"Loading info dictionary... Done.");
    }
    return _info;
}

- (id) objectForInfoDictionaryKey:(NSString*)key
{
    id result = [[self infoDictionary] objectForKey:key];
    DLOG(@"objectForInfoDictionaryKey:%@ -> %@", key, result);
    return result;

}

@end
