#import "AP_UserDefaults.h"

#import "AP_FileUtils.h"

#import <UIKit/UIKit.h>

@implementation AP_UserDefaults {
    BOOL _dirty;
    NSMutableDictionary* _contents;
    NSTimer* _timer;
    NSString* _dir;
    NSString* _basename;
    NSMutableArray* _files;
    int _nextSeq;

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
        _dir = g_DefaultsPath.stringByDeletingLastPathComponent;
        _basename = g_DefaultsPath.lastPathComponent;

        // Kick off background thread
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(backgroundLoop:) object:nil];
        [_thread start];

        NSLog(@"Scanning for UserDefaults...");
        {
            NSMutableDictionary* validFiles = [NSMutableDictionary dictionary];

            NSArray* allFiles = getDirectoryContents(_dir);
            for (NSString* f in allFiles) {
                if ([f isEqualToString:_basename]) {
                    // This is an old-style uncompressed file. Give it sequence number 0.
                    [validFiles setObject:f forKey:@(0)];
                    NSLog(@"  * %@", f);
                    continue;
                }

                NSScanner* scanner = [NSScanner scannerWithString:f];
                int seq;
                if ([scanner scanString:_basename intoString:NULL]
                    && [scanner scanString:@"." intoString:NULL]
                    && [scanner scanInt:&seq]
                    && [scanner scanString:@".gz" intoString:NULL]) {
                    // New-style compressed file with a sequence number.
                    [validFiles setObject:f forKey:@(seq)];
                    NSLog(@"  * %@", f);
                    continue;
                }
            }

            _files = [NSMutableArray array];
            _nextSeq = 1;

            NSArray* seqs = validFiles.allKeys;
            seqs = [seqs sortedArrayUsingSelector:@selector(compare:)];
            for (NSNumber* seq in seqs) {
                NSString* f = validFiles[seq];
                [_files addObject:f];
                _nextSeq = seq.intValue + 1;
            }
        }

        // Attempt to load the file with the highest sequence number
        while (_files.count) {
            NSString* path = [_dir stringByAppendingPathComponent:_files.lastObject];
            NSLog(@"Loading %@...", path);

            NSDictionary* dict;
            if ([path.pathExtension isEqualToString:@"gz"]) {
                NSData* data = [NSData dataWithContentsOfFile:path];
                data = gunzip(data);
                NSError *error = nil;
                dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if (error) {
                    NSLog(@"Error loading JSON data: %@", error);
                    dict = nil;
                }
            } else {
                dict = [NSDictionary dictionaryWithContentsOfFile:path];
            }

            if (!dict) {
                NSLog(@"Failed to load %@!", path.lastPathComponent);
            } else if (![dict isKindOfClass:[NSDictionary class]]) {
                NSLog(@"Error: root structure is not a dictionary");
            } else {
                NSLog(@"Loading %@... Success!", path);
                _contents = [dict mutableCopy];
                break;
            }

            // Failed -- discard this file and try the previous one
            [_files removeLastObject];
            continue;
        }

        if (!_contents) {
            _contents = [NSMutableDictionary dictionary];
        }
    }
    return self;
}

typedef void (^VoidBlock)();
typedef VoidBlock (^Thunk)();

- (void) doInBackground:(Thunk)thunk
{
    NSThread* caller = [NSThread currentThread];
    [self runOnThread:_thread block:^{
        VoidBlock block = thunk();
        [self runOnThread:caller block:block];
    }];
}

- (void) runBlock:(VoidBlock)block
{
    if (block) {
        block();
    }
}

- (void) runOnThread:(NSThread*)thread block:(VoidBlock)block
{
    [self performSelector:@selector(runBlock:) onThread:thread withObject:block waitUntilDone:NO];
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
            return NO;
        }
        int seq = _nextSeq++;
        NSString* filename = [NSString stringWithFormat:@"%@.%d.gz", _basename, seq];
        [_files addObject:filename];

        NSString* path = [_dir stringByAppendingPathComponent:filename];
        [self doInBackground:^{
            [[UIApplication sharedApplication] lockQuit];
            {
                NSLog(@"Writing %@...", path);
                [gzip(data) writeToFile:path atomically:NO];
                NSLog(@"Writing %@... Done", path);
            }
            [[UIApplication sharedApplication] unlockQuit];
            return ^{
                [self maybeEraseOldestFile];
            };
        }];
    }
    return YES;
}

- (void) maybeEraseOldestFile
{
    if (_files.count > 10) {
        NSString* f = _files.firstObject;
        [_files removeObjectAtIndex:0];
        [self eraseFile:[_dir stringByAppendingPathComponent:f]];
    }
}

- (void) eraseFile:(NSString*)f
{
    [self doInBackground:^{
        [[UIApplication sharedApplication] lockQuit];
        {
            NSLog(@"UserDefaults: deleting %@...", f);
            NSError* err = nil;
            [[NSFileManager defaultManager] removeItemAtPath:f error:&err];
            if (err) {
                NSLog(@"Error deleting %@: %@", f, err);
            } else {
                NSLog(@"UserDefaults: deleting %@... Done", f);
            }
        }
        [[UIApplication sharedApplication] unlockQuit];
        return ^{};
    }];
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
    if ([self boolForKey:defaultName] != value) {
        NSNumber* number = [NSNumber numberWithBool:value];
        [_contents setObject:number forKey:defaultName];
        _dirty = YES;
    }
}

- (NSInteger) integerForKey:(NSString*)defaultName
{
    NSNumber* number = [_contents objectForKey:defaultName];
    return [number integerValue];
}

- (void) setInteger:(NSInteger)value forKey:(NSString*)defaultName
{
    if ([self integerForKey:defaultName] != value) {
        NSNumber* number = [NSNumber numberWithInteger:value];
        [_contents setObject:number forKey:defaultName];
        _dirty = YES;
    }
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
