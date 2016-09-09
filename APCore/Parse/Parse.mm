#import "Parse.h"

#import <curl/curl.h>

@implementation Parse {
    NSThread* _thread;
    struct curl_slist* _headers;
    CURL* _curl;
}

- (instancetype) initWithApplicationId:(NSString *)applicationId clientKey:(NSString *)clientKey
{
    self = [super init];
    if (self) {
        _headers = curl_slist_append(_headers,
            [@"X-Parse-Application-Id: " stringByAppendingString:applicationId].UTF8String);
        _headers = curl_slist_append(_headers,
            [@"X-Parse-REST-API-Key: " stringByAppendingString:clientKey].UTF8String);
        _headers = curl_slist_append(_headers,
            "Content-Type: application/json");

        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(mainLoop:) object:nil];
        [_thread start];
    }
    return self;
}

- (void) dealloc
{
    curl_slist_free_all(_headers);
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

//static NSString* escape(CURL* curl, NSObject* s) {
//    const char* c = s.description.UTF8String;
//    const char* e = curl_easy_escape(curl, c, 0);
//    NSString* result = e ? [NSString stringWithUTF8String:e] : nil;
//    curl_free((void*) e);
//    return result;
//}
//
//static size_t write_devnull(const char *ptr, size_t size, size_t nmemb, void *userdata) {
//    return size * nmemb;
//}

struct write_context {
    write_context() : chunks([NSMutableArray array]) {}

    void add(NSData* data) {
        [chunks addObject:data];
    }

    NSData* get() {
        size_t len = 0;
        for (NSData* d in chunks) {
            len += d.length;
        }
        NSMutableData* result = [NSMutableData dataWithCapacity:len];
        for (NSData* d in chunks) {
            [result appendData:d];
        }
        return result;
    }

private:
    NSMutableArray* chunks;
};

static size_t write_func(const char* ptr, size_t size, size_t nmemb, void* userdata) {
    write_context* data = (struct write_context*)userdata;
    NSData* d = [NSData dataWithBytes:ptr length:size * nmemb];
    data->add(d);
    return size * nmemb;
}

- (NSError*) parseError:(NSString*)err
{
    NSLog(@"*** Parse error: %@", err);
    NSDictionary* info = @{ NSLocalizedDescriptionKey: err };
    return [NSError errorWithDomain:@"Parse" code:-1 userInfo:info];
}

- (void) call:(NSString*)function args:(NSDictionary*)args block:(void (^)(NSError*, NSString*))block
{
    [self doInBackground:^{
        curl_easy_reset(_curl);
        curl_easy_setopt(_curl, CURLOPT_HTTPHEADER, _headers);
        curl_easy_setopt(_curl, CURLOPT_ACCEPT_ENCODING, "gzip, deflate");
#ifdef ANDROID
        // We don't currently have a good way of storing the CA bundle on Android.
        curl_easy_setopt(_curl, CURLOPT_SSL_VERIFYPEER, 0);
#endif

        NSString* url = [@"https://api.parse.com/1/functions/" stringByAppendingString:function];
        curl_easy_setopt(_curl, CURLOPT_URL, url.UTF8String);

        NSError* error = nil;
        NSData* input = [NSJSONSerialization dataWithJSONObject:args options:0 error:&error];
        if (error) {
            return ^{
                block(error, nil);
            };
        }
        curl_easy_setopt(_curl, CURLOPT_POSTFIELDSIZE, input.length);
        curl_easy_setopt(_curl, CURLOPT_POSTFIELDS, input.bytes);

        curl_easy_setopt(_curl, CURLOPT_WRITEFUNCTION, write_func);
        write_context w;
        curl_easy_setopt(_curl, CURLOPT_WRITEDATA, &w);

        CURLcode err = curl_easy_perform(_curl);
        if (err) {
            NSString* e = [NSString stringWithUTF8String:curl_easy_strerror(err)];
            return ^{
                block([self parseError:e], nil);
            };
        }
        
        NSData* data = w.get();
        NSLog(@"Parse call returned: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

        NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (error) {
            return ^{
                block(error, nil);
            };
        }

        if (![dict isKindOfClass:[NSDictionary class]]) {
            return ^{
                block([self parseError:@"JSON returned by Parse isn't a dictionary"], nil);
            };
        }

        NSString* e = dict[@"error"];
        if (e) {
            return ^{
                block([self parseError:e], nil);
            };
        }

        NSString* result = dict[@"result"];
        if (!result) {
            return ^{
                block([self parseError:@"no 'result' in result"], nil);
            };
        }

        // Whew, we actually have a valid result!
        return ^{
            block(nil, result);
        };
    }];
}

- (void) save:(NSString*)className data:(NSDictionary*)data block:(void (^)(NSError*))block
{
    [self doInBackground:^{
        curl_easy_reset(_curl);
        curl_easy_setopt(_curl, CURLOPT_HTTPHEADER, _headers);
        curl_easy_setopt(_curl, CURLOPT_ACCEPT_ENCODING, "gzip, deflate");
#ifdef ANDROID
        // We don't currently have a good way of storing the CA bundle on Android.
        curl_easy_setopt(_curl, CURLOPT_SSL_VERIFYPEER, 0);
#endif

        NSString* url = [@"https://api.parse.com/1/classes/" stringByAppendingString:className];
        curl_easy_setopt(_curl, CURLOPT_URL, url.UTF8String);

        NSError* error = nil;
        NSData* input = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
        if (error) {
            return ^{
                block(error);
            };
        }
        curl_easy_setopt(_curl, CURLOPT_POSTFIELDSIZE, input.length);
        curl_easy_setopt(_curl, CURLOPT_POSTFIELDS, input.bytes);

        curl_easy_setopt(_curl, CURLOPT_WRITEFUNCTION, write_func);
        write_context w;
        curl_easy_setopt(_curl, CURLOPT_WRITEDATA, &w);

        CURLcode err = curl_easy_perform(_curl);
        if (err) {
            NSString* e = [NSString stringWithUTF8String:curl_easy_strerror(err)];
            return ^{
                block([self parseError:e]);
            };
        }
        
        NSData* data = w.get();
        NSLog(@"Parse save returned: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

        NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (error) {
            return ^{
                block(error);
            };
        }

        if (![dict isKindOfClass:[NSDictionary class]]) {
            return ^{
                block([self parseError:@"JSON returned by Parse isn't a dictionary"]);
            };
        }

        NSString* e = dict[@"error"];
        if (e) {
            return ^{
                block([self parseError:e]);
            };
        }

        NSString* result = dict[@"objectId"];
        if (!result) {
            return ^{
                block([self parseError:@"no 'objectId' in result"]);
            };
        }

        // Whew, we actually have a valid result!
        NSLog(@"Parse created objectId: %@", result);
        return ^{
            block(nil);
        };
    }];
}

static NSString* escape(CURL* curl, NSObject* s) {
    const char* c = s.description.UTF8String;
    const char* e = curl_easy_escape(curl, c, 0);
    NSString* result = e ? [NSString stringWithUTF8String:e] : nil;
    curl_free((void*) e);
    return result;
}

- (void) query:(NSString*)className where:(NSDictionary*)data block:(void (^)(NSError*, NSArray*))block
{
    [self doInBackground:^{
        curl_easy_reset(_curl);
        curl_easy_setopt(_curl, CURLOPT_HTTPHEADER, _headers);
        curl_easy_setopt(_curl, CURLOPT_ACCEPT_ENCODING, "gzip, deflate");
#ifdef ANDROID
        // We don't currently have a good way of storing the CA bundle on Android.
        curl_easy_setopt(_curl, CURLOPT_SSL_VERIFYPEER, 0);
#endif

        NSError* error = nil;
        NSData* input = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
        if (error) {
            return ^{
                block(error, nil);
            };
        }
        NSString* query = escape(_curl, [[NSString alloc] initWithData:input encoding:NSUTF8StringEncoding]);
        NSString* url = [NSString stringWithFormat:@"https://api.parse.com/1/classes/%@?where=%@&limit=1000", className, query];
        curl_easy_setopt(_curl, CURLOPT_URL, url.UTF8String);

        curl_easy_setopt(_curl, CURLOPT_WRITEFUNCTION, write_func);
        write_context w;
        curl_easy_setopt(_curl, CURLOPT_WRITEDATA, &w);

        CURLcode err = curl_easy_perform(_curl);
        if (err) {
            NSString* e = [NSString stringWithUTF8String:curl_easy_strerror(err)];
            return ^{
                block([self parseError:e], nil);
            };
        }

        NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:w.get() options:0 error:&error];
        if (error) {
            return ^{
                block(error, nil);
            };
        }

        if (![dict isKindOfClass:[NSDictionary class]]) {
            return ^{
                block([self parseError:@"JSON returned by Parse isn't a dictionary"], nil);
            };
        }

        NSString* e = dict[@"error"];
        if (e) {
            return ^{
                block([self parseError:e], nil);
            };
        }

        NSArray* result = dict[@"results"];
        if (!result) {
            return ^{
                block([self parseError:@"no 'results' in result"], nil);
            };
        }

        // Whew, we actually have a valid result!
        NSLog(@"Parse query returned %d results", (int) result.count);
        return ^{
            block(nil, result);
        };
    }];
}

- (void) mainLoop:(id)ignored
{
    @autoreleasepool {
        CURLcode err = curl_global_init(CURL_GLOBAL_DEFAULT);
        if (err) {
            NSLog(@"*** curl_global_init() failed: %s", curl_easy_strerror(err));
            return;
        }

        NSLog(@"Parse: starting");

        _curl = curl_easy_init();
        if (!_curl) {
            NSLog(@"*** ERROR - curl_easy_init() failed!");
            return;
        }
    }

    while (true) {
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
}

@end
