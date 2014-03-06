#pragma once

#import <Foundation/Foundation.h>

@interface NSDictionary(AP_InitWithData)

// As initWithContentsOfFile:, but passing in the file data directly.
// This is useful for reading embedded resources.
- (instancetype) initWithPlistData:(NSData*)data;

+ (instancetype) dictionaryWithPlistData:(NSData*)data;

@end
