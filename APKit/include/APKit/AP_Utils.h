#pragma once

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import <UIKit/UIKit.h>

#import "AP_Window.h"

#define AP_CLAMP(x, minimum, maximum) (MIN( MAX((x),(minimum)), (maximum)))

#define AP_DEVICE_METRIC(m) [AP_Window iPhone:(m)[0] iPad:(m)[1]]

static inline double AP_Ease(double t)
{
    t = AP_CLAMP(t, 0.0, 1.0);
    return t * t * t * (t * (t * 6 - 15) + 10);
}

static inline double AP_EaseIn(double t)
{
    t = AP_CLAMP(t, 0.0, 1.0);
    return t * (2 - t);
}

static inline double AP_EaseOut(double t)
{
    t = AP_CLAMP(t, 0.0, 1.0);
    return t * t;
}

static inline double AP_Lerp(double v1, double v2, double t) {
    return v1 + t*(v2-v1);
}

static inline GLKVector4 AP_ColorToVector(UIColor* color) {
    return color.rgba;
}
static inline UIColor* AP_VectorToColor(GLKVector4 rgba) {
    return [UIColor colorWithRgba:rgba];
}

#if defined(OSX)

#import <mach/mach_time.h>

static inline double AP_TimeInSeconds() {
    uint64_t t = mach_absolute_time();
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    t *= info.numer;
    t /= info.denom;
    return t / (double) NSEC_PER_SEC;
}

#elif defined(LINUX) || defined(ANDROID)

#import <time.h>

static inline double AP_TimeInSeconds() {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + (double) t.tv_nsec / 1000000000.0;
}

#elif defined(WINDOWS)

#import <windows.h>

static inline double AP_TimeInSeconds() {
    LARGE_INTEGER frequency;
    LARGE_INTEGER counter;
    QueryPerformanceFrequency(&frequency);
    QueryPerformanceCounter(&counter);
    return counter.QuadPart / (double)frequency.QuadPart;
}

#else
#error Unknown OS!
#endif
