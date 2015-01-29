#pragma once

#import <Foundation/Foundation.h>

#include <string.h>

#define AP_FILE (strrchr(__FILE__, '/') ? strrchr(__FILE__, '/') + 1 : __FILE__)

#define AP_LogError(...) AP_LogError_(AP_FILE, __LINE__, __VA_ARGS__)
#define AP_LogFatal(...) AP_LogError_(AP_FILE, __LINE__, __VA_ARGS__)

// DLOG() logs in debug builds only
#ifdef NDEBUG
#define DLOG(...)
#else
#define DLOG(...) NSLog(__VA_ARGS__)
#endif

#ifdef __cplusplus
extern "C" {
#endif

extern void AP_LogError_(const char* file, int line, const char* format, ...);
extern void AP_LogFatal_(const char* file, int line, const char* format, ...);

#ifdef __cplusplus
} // extern "C"
#endif
