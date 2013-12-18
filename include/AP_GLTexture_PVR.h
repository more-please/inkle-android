#pragma once

#import <Foundation/Foundation.h>

#import "AP_GLTexture.h"

// Loads a PowerVR-formatted texture.
// Of course, it won't actually work on a non-PowerVR device...

@interface AP_GLTexture_PVR : AP_GLTexture

- (AP_GLTexture_PVR*) initWithData:(NSData*)data;

+ (BOOL) isPVR:(NSData*)data;
+ (AP_GLTexture*) withData:(NSData*)data;

@end
