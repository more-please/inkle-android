#pragma once

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import <UIKit/UIKit.h>

#import "AP_Window.h"

#define AP_CLAMP(x, minimum, maximum) (MIN( MAX((x),(minimum)), (maximum)))

#define AP_DEVICE_METRIC(m) [AP_Window iPhone:(m)[0] iPad:(m)[1]]

static inline float AP_Ease(float t)
{
    return 3*t*t - 2*t*t*t;
}

static inline float AP_Lerp(float v1, float v2, float t) {
    return v1 + t*(v2-v1);
}

#ifdef ANDROID
static inline GLKVector4 AP_ColorToVector(UIColor* color) {
    return color.rgba;
}
static inline UIColor* AP_VectorToColor(GLKVector4 rgba) {
    return [UIColor colorWithRgba:rgba];
}

#else
extern GLKVector4 AP_ColorToVector(UIColor*);
extern UIColor* AP_VectorToColor(GLKVector4);
#endif

#ifdef ANDROID

#import <time.h>

static inline double AP_TimeInSeconds() {
    struct timespec t;
    int result = clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + (double) t.tv_nsec / 1000000000.0;
}

#else

#import <mach/mach_time.h>

static inline double AP_TimeInSeconds() {
    uint64_t t = mach_absolute_time();
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    t *= info.numer;
    t /= info.denom;
    return t / (double) NSEC_PER_SEC;
}
#endif
