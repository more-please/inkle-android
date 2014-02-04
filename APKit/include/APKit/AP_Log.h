#pragma once

#import <Foundation/Foundation.h>

#define AP_LogError(...) AP_LogError_(__FILE__, __LINE__, __VA_ARGS__)
#define AP_LogFatal(...) AP_LogError_(__FILE__, __LINE__, __VA_ARGS__)

#ifdef __cplusplus
extern "C" {
#endif

extern void AP_LogError_(const char* file, int line, const char* format, ...);
extern void AP_LogFatal_(const char* file, int line, const char* format, ...);

#ifdef __cplusplus
} // extern "C"
#endif
