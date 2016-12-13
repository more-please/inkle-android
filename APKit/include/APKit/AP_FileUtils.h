#pragma once

#include <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

NSArray* getDirectoryContents(NSString*);
NSData* gzip(NSData*);
NSData* gunzip(NSData*);

#ifdef __cplusplus
} // extern "C"
#endif
