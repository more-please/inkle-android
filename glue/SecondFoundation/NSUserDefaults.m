#import "NSUserDefaults.h"

#import "GlueCommon.h"

@implementation NSUserDefaults {
    BOOL _dirty;
    NSMutableDictionary* _contents;
    NSTimer* _timer;
    NSString* _path;
}

static NSString* g_DocumentsDir = nil;
static NSUserDefaults* g_Defaults = nil;

+ (void) setDocumentsDir:(NSString*)dir
{
    g_DocumentsDir = dir;
}

+ (NSUserDefaults*) standardUserDefaults
{
    if (!g_Defaults) {
        g_Defaults = [[NSUserDefaults alloc] init];
    }
    return g_Defaults;
}

- (id) init
{
    NSAssert(!g_Defaults, @"NSUserDefaults already instantiated");
    self = [super init];
    if (self) {
        NSAssert(g_DocumentsDir, @"Documents dir wasn't set");
        _path = [g_DocumentsDir stringByAppendingPathComponent:@"NSUserDefaults"];

        NSDictionary* data;
        if ([[NSFileManager defaultManager] fileExistsAtPath:_path]) {
            data = [NSDictionary dictionaryWithContentsOfFile:_path];
            if (!data) {
                NSLog(@"Failed to load NSUserDefaults!");
            }
        }
        _contents = data ? [data mutableCopy] : [NSMutableDictionary dictionary];

        _timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    }
    return self;
}

- (void) timerFired:(NSTimer*)timer
{
    [self synchronize];
}

- (BOOL) synchronize
{
    if (_dirty) {
        _dirty = NO;
        [self performSelectorInBackground:@selector(saveDictionary:) withObject:[_contents copy]];
    }
    return YES;
}

- (void) saveDictionary:(NSDictionary*)data
{
    BOOL success = [data writeToFile:_path atomically:YES];
    if (!success) {
        NSLog(@"Failed to save NSUserDefaults to path: %@", _path);
    }
}

- (id) objectForKey:(NSString*)defaultName
{
    return [_contents objectForKey:defaultName];
}

- (void) setObject:(id)value forKey:(NSString*)defaultName
{
    [_contents setObject:value forKey:defaultName];
    _dirty = YES;
}

- (void) removeObjectForKey:(NSString*)key
{
    [_contents removeObjectForKey:key];
    _dirty = YES;
}

- (BOOL) boolForKey:(NSString*)defaultName
{
    NSNumber* number = [_contents objectForKey:defaultName];
    return [number boolValue];
}

- (void) setBool:(BOOL)value forKey:(NSString*)defaultName
{
    NSNumber* number = [NSNumber numberWithBool:value];
    [_contents setObject:number forKey:defaultName];
}

- (NSInteger) integerForKey:(NSString*)defaultName
{
    NSNumber* number = [_contents objectForKey:defaultName];
    return [number integerValue];
}

- (NSString*) stringForKey:(NSString*)defaultName
{
    return [_contents objectForKey:defaultName];
}

- (NSArray*) stringArrayForKey:(NSString*)defaultName
{
    return [_contents objectForKey:defaultName];
}

- (NSDictionary*) dictionaryRepresentation
{
    return _contents;
}

@end

// Declared in GSPrivate.h but defined in NSUserDefaults.m, bah

typedef enum {
  GSMacOSXCompatible,           // General behavior flag.
  GSOldStyleGeometry,           // Control geometry string output.
  GSLogSyslog,              // Force logging to go to syslog.
  GSLogThread,              // Include thread ID in log message.
  NSWriteOldStylePropertyLists,     // Control PList output.
  GSUserDefaultMaxFlag          // End marker.
} GSUserDefaultFlagType;

BOOL GSPrivateDefaultsFlag(GSUserDefaultFlagType type) {
    switch(type) {
        GSMacOSXCompatible:
            // Seems like a good idea...
            return YES;

        default:
            return NO;
    }
}

NSDictionary* GSPrivateDefaultLocale() {
    return [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
}
