#pragma once

#import <Foundation/Foundation.h>

#define AP_LogError(...) AP_LogError_(__FILE__, __LINE__, __VA_ARGS__)
#define AP_LogFatal(...) AP_LogError_(__FILE__, __LINE__, __VA_ARGS__)

void AP_LogError_(const char* file, int line, const char* format, ...);
void AP_LogFatal_(const char* file, int line, const char* format, ...);
