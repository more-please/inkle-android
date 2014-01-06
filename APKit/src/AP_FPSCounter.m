#import "AP_FPSCounter.h"
#import "AP_Utils.h"

const int NUM_FRAME_TIMES = 16;

@implementation AP_FPSCounter {
    unsigned _count;
    double _frameTimes[NUM_FRAME_TIMES];
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
    _frameTimes[++_count % NUM_FRAME_TIMES] = AP_TimeInSeconds();
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