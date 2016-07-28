#pragma once

#import <Foundation/Foundation.h>

#import "AP_Log.h"

// Use this macro to ensure raw init: isn't called.
#define AP_BAN_EVIL_INIT \
    - (instancetype) init \
    { \
        AP_LogFatal("Don't call init!"); \
        return nil; \
    }

// Log an error and return if the given condition is false.
#define AP_CHECK(cond, ret) \
    if (!(cond)) { \
        AP_LogError("Check failed: %s", #cond); \
        ret; \
    }

// Log an error and return unless a == b
#define AP_CHECK_EQ(a, b, ret) \
    do { \
        int aValue = a; \
        int bValue = b; \
        if (aValue != bValue) { \
            AP_LogError("Check failed: %s (%d) == %s (%d)", #a, aValue, #b, bValue); \
            ret; \
        } \
    } while(0)

// Log an error and return unless a >= b
#define AP_CHECK_GE(a, b, ret) \
    do { \
        int aValue = a; \
        int bValue = b; \
        if (aValue < bValue) { \
            AP_LogError("Check failed: %s (%d) >= %s (%d)", #a, aValue, #b, bValue); \
            ret; \
        } \
    } while(0)

// Log an error and return nil if glGetError() isn't GL_NO_ERROR
#define AP_CHECK_GL(message, ret) \
    do { \
        GLenum err = glGetError(); \
        if (err != GL_NO_ERROR) { \
            AP_LogError("%s (GL error: 0x%x)", message, err); \
            ret; \
        } \
    } while(0)

// #define _GL(cmd, ...) gl ## cmd(__VA_ARGS__)
#define _GL(cmd, ...) do { gl ## cmd(__VA_ARGS__); AP_CHECK_GL(#cmd,); } while(0)
// #define _GL(cmd, ...) do { NSLog(@"%s:%d %s", __FILE__, __LINE__, #cmd); gl ## cmd(__VA_ARGS__); AP_CHECK_GL(#cmd,); } while(0)

#define AP_NOT_IMPLEMENTED \
    do { \
        static int count = 0; \
        if (count < 5) { \
            ++count; \
            AP_LogError("Not implemented!"); \
        } \
    } while(0)
