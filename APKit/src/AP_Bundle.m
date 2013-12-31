#import "AP_Bundle.h"

#import "AP_Check.h"

@implementation AP_Bundle {
    NSMutableArray* _paks;
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
    self = [super init];
    if (self) {
        _paks = [NSMutableArray array];
    }
    return self;
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
    for (AP_PakReader* pak in g_Bundle->_paks) {
        NSData* data = [pak getFile:fullName];
        if (data) {
            return data;
        }
    }
    NSString* path = [[AP_Bundle mainBundle] pathForResource:name ofType:ext];
    if (!path) {
        return nil;
    }
#ifdef ANDROID
    return [NSData dataWithContentsOfMappedFile:path];
#else
    return [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil];
#endif
}

#ifdef ANDROID
+ (AP_Bundle*) mainBundle
{
    static AP_Bundle* s_MainBundle;
    if (!s_MainBundle) {
        s_MainBundle = [[AP_Bundle alloc] init];
    }
    return s_MainBundle;
}
#else
+ (NSBundle*) mainBundle
{
    return [NSBundle mainBundle];
}
#endif

- (NSArray*) pathsForResourcesOfType:(NSString*)ext inDirectory:(NSString*)dir
{
    NSLog(@"pathsForResourcesOfType:%@ inDirectory:%@", ext, dir);
    return nil;
}

- (NSString*) pathForResource:(NSString*)name ofType:(NSString*)ext
{
    NSLog(@"pathForResource:%@ ofType:%@", name, ext);
    return nil;
}

- (NSURL*) URLForResource:(NSString*)name withExtension:(NSString*)ext;
{
    NSLog(@"URLForResource:%@ withExtension:%@", name, ext);
    return nil;
}

- (NSDictionary*) infoDictionary
{
    NSLog(@"infoDictionary");
    return nil;
}

- (id) objectForInfoDictionaryKey:(NSString*)key
{
    NSLog(@"objectForInfoDictionaryKey:%@", key);
    return nil;
}

@end
