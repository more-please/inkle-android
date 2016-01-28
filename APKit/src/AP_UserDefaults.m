#import "AP_UserDefaults.h"

#ifndef APPLE_RUNTIME
#import <Foundation/Foundation.h>
#endif

@implementation AP_UserDefaults {
    BOOL _dirty;
    NSMutableDictionary* _contents;
    NSTimer* _timer;
    NSString* _path;
}

static NSString* g_DocumentsDir = nil;
static AP_UserDefaults* g_Defaults = nil;

+ (void) setDocumentsDir:(NSString*)dir
{
    g_DocumentsDir = dir;
#ifndef APPLE_RUNTIME
    [NSUserDefaults setDocumentsDir:dir];
#endif
}

+ (AP_UserDefaults*) standardUserDefaults
{
    if (!g_Defaults) {
        g_Defaults = [[AP_UserDefaults alloc] init];
    }
    return g_Defaults;
}

- (id) init
{
    NSAssert(!g_Defaults, @"AP_UserDefaults already instantiated");
    self = [super init];
    if (self) {
        NSAssert(g_DocumentsDir, @"Documents dir wasn't set");
        _path = [g_DocumentsDir stringByAppendingPathComponent:@"AP_UserDefaults.plist"];

        NSDictionary* data = nil;
        if ([[NSFileManager defaultManager] fileExistsAtPath:_path]) {
            data = [NSDictionary dictionaryWithContentsOfFile:_path];
            if (!data) {
                NSLog(@"Failed to load AP_UserDefaults!");
            }
        }
        _contents = data ? [data mutableCopy] : [NSMutableDictionary dictionary];

        _timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
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
    NSLog(@"Writing %@...", _path);
    BOOL success = [data writeToFile:_path atomically:YES];
    NSLog(@"Writing %@... Done!", _path);
    if (!success) {
        NSLog(@"Failed to save AP_UserDefaults to path: %@", _path);
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
    _dirty = YES;
}

- (NSInteger) integerForKey:(NSString*)defaultName
{
    NSNumber* number = [_contents objectForKey:defaultName];
    return [number integerValue];
}

- (void) setInteger:(NSInteger)value forKey:(NSString*)defaultName
{
    NSNumber* number = [NSNumber numberWithInteger:value];
    [_contents setObject:number forKey:defaultName];
    _dirty = YES;
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
