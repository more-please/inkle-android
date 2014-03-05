#import "AP_Bundle.h"

#import "AP_Check.h"

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
    NSString* fullName = name;
    if (ext) {
        fullName = [name stringByAppendingString:ext];
    }

    // Try loading from the .pak file
    for (AP_PakReader* pak in g_Bundle->_paks) {
        NSData* data = [pak getFile:fullName];
        if (data) {
            return data;
        }
    }

    // Try loading a loose file from the .obb
    NSString* path = [[AP_Bundle mainBundle] pathForResource:name ofType:ext];
    if (path) {
#ifdef ANDROID
        return [NSData dataWithContentsOfMappedFile:path];
#else
        return [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil];
#endif
    }

#ifdef ANDROID
    // Try loading an Android asset
    return [[AP_Application sharedApplication] getResource:fullName];
#else
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

- (NSArray*) pathsForResourcesOfType:(NSString*)ext inDirectory:(NSString*)dir
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* path = [_root stringByAppendingPathComponent:dir];
    NSMutableArray* result = [NSMutableArray array];
    NSError* error;
    for (NSString* s in [fm contentsOfDirectoryAtPath:path error:&error]) {
        if ([s hasSuffix:ext]) {
            NSString* file = [path stringByAppendingPathComponent:s];
            [result addObject:file];
        }
    }
    if (error) {
        NSLog(@"*** [NSBundle pathsForResourcesOfType:\"%@\" inDirectory:\"%@\"]: %@", ext, dir, error);
    }
    return result;
}

- (NSString*) pathForResource:(NSString*)name ofType:(NSString*)ext
{
    NSString* path = [self.root stringByAppendingPathComponent:name];
    if (ext) {
        path = [path stringByAppendingPathExtension:ext];
    }
    return [[NSFileManager defaultManager] fileExistsAtPath:path] ? path : nil;
}

- (NSString*) pathForResource:(NSString*)name ofType:(NSString*)ext inDirectory:(NSString*)subpath
{
    return [self pathForResource:[subpath stringByAppendingPathComponent:name] ofType:ext];
}

- (NSURL*) URLForResource:(NSString*)name withExtension:(NSString*)ext;
{
    NSString* path = [self pathForResource:name ofType:ext];
    if (!path) {
        return nil;
    }
    return [[NSURL alloc] initFileURLWithPath:path];
}

- (NSDictionary*) infoDictionary
{
    if (!_info) {
        NSLog(@"Loading info dictionary...");
        NSString* path = [self pathForResource:@"Info" ofType:@"plist"];
        _info = [[NSDictionary alloc] initWithContentsOfFile:path];
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
