#import "NSUserDefaults.h"

#import "GlueCommon.h"

@implementation NSUserDefaults {
    NSMutableDictionary* _contents;
}

static NSUserDefaults* g_Defaults = nil;

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
        _contents = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id) objectForKey:(NSString*)defaultName
{
    return [_contents objectForKey:defaultName];
}

- (void) setObject:(id)value forKey:(NSString*)defaultName
{
    [_contents setObject:value forKey:defaultName];
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

- (BOOL) synchronize
{
    GLUE_NOT_IMPLEMENTED;
    return NO;
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
