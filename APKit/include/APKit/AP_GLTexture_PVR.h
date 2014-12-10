#pragma once

#import <Foundation/Foundation.h>

#import "AP_GLTexture.h"

// Loads a PowerVR-formatted texture.
// Of course, it won't actually work on a non-PowerVR device...

@interface AP_GLTexture (PVR)

+ (BOOL) isPVR:(NSData*)data;

- (BOOL) loadPVR:(NSData*)data;

@end
