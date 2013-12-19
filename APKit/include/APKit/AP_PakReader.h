#pragma once

#import <Foundation/Foundation.h>

@interface AP_PakReader : NSObject

- (AP_PakReader*) initWithData:(NSData*)data;

- (NSData*) getFile:(NSString*)filename;

+ (AP_PakReader*) readerWithData:(NSData*)data;
+ (AP_PakReader*) readerWithMemoryMappedFile:(NSString*)filename;

@end
