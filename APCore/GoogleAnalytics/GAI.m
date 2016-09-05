#import "GAI.h"

#import <curl/curl.h>

#import "GAITracker.h"
#import "GAIFields.h"

static GAI* g_shared = nil;

static const int kTimerInterval = 20;

@implementation GAI {
    AP_GAITracker* _defaultTracker;
    BOOL _done;

    NSThread* _thread;
    NSMutableArray* _queue; // List of dictionaries. Must only be accessed by _thread.
    CURL* _curl;
}

+ (GAI*) sharedInstance
{
    if (!g_shared) {
        g_shared = [[GAI alloc] init];
    }
    return g_shared;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(mainLoop:) object:nil];
        _queue = [NSMutableArray array];
        [_thread start];
    }
    return self;
}

- (void) send:(NSDictionary*)params
{
    if (_done) {
        return; // Probably failed to initialize curl
    }

    NSMutableDictionary* p = [params mutableCopy];
    p[kGAIQueueTime] = [NSDate date];

    // Shuffle over to the background thread
    [self performSelector:@selector(backgroundSend:) onThread:_thread withObject:p waitUntilDone:NO];
}

- (void) backgroundSend:(NSDictionary*)params
{
    [_queue addObject:params];
}

static NSString* escape(CURL* curl, NSObject* s) {
    const char* c = s.description.UTF8String;
    const char* e = curl_easy_escape(curl, c, 0);
    NSString* result = e ? [NSString stringWithUTF8String:e] : nil;
    curl_free((void*) e);
    return result;
}

static size_t write_devnull(char *ptr, size_t size, size_t nmemb, void *userdata) {
    return size * nmemb;
}

- (void) timerFired:(NSTimer*)timer
{
    NSMutableArray* queue = _queue;
    _queue = [NSMutableArray array];

    if (!_curl) {
        _curl = curl_easy_init();
    }
    if (!_curl) {
        NSLog(@"*** ERROR - curl_easy_init() failed!");
        return;
    }

    curl_easy_setopt(_curl, CURLOPT_URL, "https://ssl.google-analytics.com/collect");
    curl_easy_setopt(_curl, CURLOPT_WRITEFUNCTION, write_devnull);

    const int kMaxSize = 100;
    if (queue.count > kMaxSize) {
        NSLog(@"*** GAI queue is full, discarding %d events", (int) (queue.count - kMaxSize));
        NSIndexSet* indices = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(kMaxSize, queue.count - kMaxSize)];
        [queue removeObjectsAtIndexes:indices];
    }

    while (queue.count) {
        NSDictionary* head = [queue firstObject];
        [queue removeObjectAtIndex:0];

        // https://developers.google.com/analytics/devguides/collection/protocol/v1/parameters
        NSMutableDictionary* p = [head mutableCopy];
        NSDate* now = [NSDate date];
        NSTimeInterval queueTime = [now timeIntervalSinceDate:p[kGAIQueueTime]];
        p[kGAIQueueTime] = [NSNumber numberWithLong:(1000 * queueTime)];

        NSMutableArray* arr = [NSMutableArray array];
        [arr addObject:@"v=1"];
        for (NSString* key in [p.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]) {
            NSString* val = escape(_curl, p[key]);
            [arr addObject:[NSString stringWithFormat:@"%@=%@", key, val]];
        }

        NSString* payload = [arr componentsJoinedByString:@"&"];
        NSLog(@"GAI: %@", payload);

        curl_easy_setopt(_curl, CURLOPT_POSTFIELDS, payload.UTF8String);
        int err = curl_easy_perform(_curl);
        if (err) {
            NSLog(@"*** curl_easy_perform() failed: %s", curl_easy_strerror(err));

            [queue insertObject:head atIndex:0];

            NSLog(@"*** Re-queuing %d log events", (int) queue.count);
            NSIndexSet* indices = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, queue.count)];
            [_queue insertObjects:queue atIndexes:indices];

            // Back off and try again later
            break;
        }
    }
}

- (void) mainLoop:(id)ignored
{
    NSTimer* timer;

    @autoreleasepool {
        NSLog(@"GAI: starting");
        timer = [NSTimer scheduledTimerWithTimeInterval:kTimerInterval target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    }

    while (!_done) {
        @autoreleasepool {
            // Run Objective-C timers.
            NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
            NSDate* now = [NSDate date];
            NSDate* nextTimer;
            do {
                nextTimer = [runLoop limitDateForMode:NSDefaultRunLoopMode];
            } while (nextTimer && [now compare:nextTimer] != NSOrderedAscending);

            if (!nextTimer) {
                nextTimer = [NSDate dateWithTimeIntervalSinceNow:1];
            }

            // Run callbacks.
            [runLoop acceptInputForMode:NSDefaultRunLoopMode beforeDate:nextTimer];
        }
    }

    [timer invalidate];

    NSLog(@"GAI: stopping");
}

- (id<GAITracker>)trackerWithTrackingId:(NSString *)trackingId
{
    AP_GAITracker* result = [[AP_GAITracker alloc] initWithTrackingId:trackingId];
    if (!_defaultTracker) {
        _defaultTracker = result;
    }
    return result;
}

- (id<GAITracker>) defaultTracker
{
    return _defaultTracker;
}

@end
