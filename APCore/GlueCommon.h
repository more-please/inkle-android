#pragma once

#import <Foundation/Foundation.h>

#import <string.h>

#define GLUE_FILE (strrchr(__FILE__, '/') ? strrchr(__FILE__, '/') + 1 : __FILE__)

#define GLUE_NOT_IMPLEMENTED \
    NSLog(@"%s:%d: not implemented!", GLUE_FILE, __LINE__)

#define GLUE_FAIL(s) \
    do { NSLog(@"%s:%d - %s", GLUE_FILE, __LINE__, s); abort(); } while(0)

#define GLUE_ASSERT(cond) \
    do { if (!(cond)) { NSLog(@"%s:%d - assertion failed: %s", GLUE_FILE, __LINE__, #cond); abort(); } while(0)
