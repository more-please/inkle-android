#pragma once

#import <Foundation/Foundation.h>

@interface NSDictionary(AP_InitWithData)

// As initWithContentsOfFile:, but passing in the file data directly.
// This is useful for reading embedded resources.
- (instancetype) initWithData:(NSData*)data;

+ (instancetype) dictionaryWithData:(NSData*)data;

@end
