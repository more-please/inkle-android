#pragma once

#import <Foundation/Foundation.h>

#define GLUE_NOT_IMPLEMENTED \
    NSLog(@"%s:%d: not implemented!", __FILE__, __LINE__)

#define GLUE_FAIL(s) \
    do { NSLog(@"%s:%d - %s", __FILE__, __LINE__, s); abort(); } while(0)

#define GLUE_ASSERT(cond) \
    do { if (!(cond)) { NSLog(@"%s:%d - assertion failed: %s", __FILE__, __LINE__, #cond); abort(); } while(0)
