#import "AP_UserDefaults.h"

#import <UIKit/UIKit.h>

@implementation AP_UserDefaults {
    BOOL _dirty;
    NSMutableDictionary* _contents;
    NSTimer* _timer;
    NSString* _path;

    NSThread* _thread;
    BOOL _done;
}

static NSString* g_DefaultsPath = nil;
static AP_UserDefaults* g_Defaults = nil;

+ (void) setDefaultsPath:(NSString*)path
{
    g_DefaultsPath = path;
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
        NSAssert(g_DefaultsPath, @"AP_UserDefaults path wasn't set");
        _path = g_DefaultsPath;

        NSLog(@"Loading %@...", _path);
        NSDictionary* data = [NSDictionary dictionaryWithContentsOfFile:_path];
        if (!data) {
            NSLog(@"Failed to load %@!", _path.lastPathComponent);
        }
        _contents = data ? [data mutableCopy] : [NSMutableDictionary dictionary];

        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(backgroundLoop:) object:nil];
        [_thread start];
    }
    return self;
}

- (void) startSyncTimer
{
    if (_timer) {
        [_timer invalidate];
    }
    _timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
}

- (void) timerFired:(NSTimer*)timer
{
    [self synchronize];
}

- (BOOL) synchronize
{
    if (_dirty) {
        _dirty = NO;
        NSError* err = nil;
        NSData* data = [NSJSONSerialization dataWithJSONObject:_contents options:0 error:&err];
        if (err) {
            NSLog(@"Error serializing NSUserDefaults: %@", err);
        } else {
            [self performSelector:@selector(saveData:) onThread:_thread withObject:data waitUntilDone:NO];
        }
    }
    return YES;
}

- (void) saveData:(NSData*)data
{
    NSError* err = nil;
    NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    if (err) {
        NSLog(@"Error deserializing NSUserDefaults: %@", err);
        return;
    }
    NSLog(@"%@", dict);

    [[UIApplication sharedApplication] lockQuit];
    {
        NSLog(@"Writing %@...", _path);
        BOOL success = [dict writeToFile:_path atomically:YES];
        NSLog(@"Writing %@... Done!", _path);
        if (!success) {
            NSLog(@"Failed to save AP_UserDefaults to path: %@", _path);
        }
    }
    [[UIApplication sharedApplication] unlockQuit];
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

// ----------------------------------------------------------

- (void) backgroundTimerFired:(NSTimer*)timer
{
    // This timer isn't used for anything; it's just that without
    // a timer, the runLoop seems to poll continuously...!
}

- (void) backgroundLoop:(id)ignored
{
    NSTimer* timer;

    @autoreleasepool {
        NSLog(@"AP_UserDefaults: starting");
        timer = [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(backgroundTimerFired:) userInfo:nil repeats:YES];
    }

    while (!_done) {
        @autoreleasepool {
            NSLog(@"[AP_UserDefaults background thread]");

            // Run Objective-C timers.
            NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
            NSDate* now = [NSDate date];
            NSDate* nextTimer;
            do {
                nextTimer = [runLoop limitDateForMode:NSDefaultRunLoopMode];
            } while (nextTimer && [now compare:nextTimer] != NSOrderedAscending);

            if (!nextTimer) {
                nextTimer = [NSDate dateWithTimeIntervalSinceNow:300];
            }

            // Run callbacks.
            [runLoop acceptInputForMode:NSDefaultRunLoopMode beforeDate:nextTimer];
        }
    }

    [timer invalidate];

    NSLog(@"AP_UserDefaults: stopping");
}

@end
