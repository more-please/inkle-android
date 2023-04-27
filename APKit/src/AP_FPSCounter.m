#import "AP_FPSCounter.h"
#import "AP_Utils.h"

#import "AP_GLBuffer.h"
#import "AP_GLTexture.h"

#ifdef ANDROID
#import <ck/ck.h>
#endif

#define NUM_FRAME_TIMES 16

@implementation AP_FPSCounter {
    unsigned _count;
    double _frameTimes[NUM_FRAME_TIMES];
    double _lastLogTime;
}

- (AP_FPSCounter*) init
{
    self = [super init];
    if (self) {
        [self reset];
    }
    return self;
}

- (void) reset {
    for (int i = 0; i < NUM_FRAME_TIMES; ++i) {
        _frameTimes[i] = AP_TimeInSeconds();
    }
    _count = 0;
}

- (void) tick {
    double t = AP_TimeInSeconds();
    _frameTimes[++_count % NUM_FRAME_TIMES] = t;
    if (_logInterval > 0 && t > (_lastLogTime + _logInterval)) {
        _lastLogTime += _logInterval;
        if (_lastLogTime < t) {
            _lastLogTime = t;
        }
        NSLog(@"FPS: %.1f, textures: %.1fMB, geometry: %.1fMB",
            self.fps,
            [AP_GLTexture totalMemoryUsage] / (1024.0 * 1024.0),
            [AP_GLBuffer totalMemoryUsage] / (1024.0 * 1024.0));
#ifdef ANDROID
        if (CkGetClipFlag()) {
            NSLog(@"*** Audio clipped ***");
            CkResetClipFlag();
        }
#endif
    }
}

- (double) fps {
    double t0 = _frameTimes[(_count + 1) % NUM_FRAME_TIMES];
    double t1 = _frameTimes[_count % NUM_FRAME_TIMES];
    return (NUM_FRAME_TIMES - 1) / (t1 - t0);
}

- (unsigned) count {
    return _count;
}

@end
