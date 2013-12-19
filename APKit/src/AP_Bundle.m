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
    NSString* path = [[NSBundle mainBundle] pathForResource:name ofType:ext];
    if (!path) {
        return nil;
    }
#ifdef ANDROID
    return [NSData dataWithContentsOfMappedFile:path];
#else
    return [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil];
#endif
}

@end
