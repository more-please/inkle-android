#pragma once

#import <Foundation/Foundation.h>

#import "AP_GLTexture.h"

// Loads a compressed texture from a KTX file.
// Does not check whether the texture is supported by the current hardware.

@interface AP_GLTexture (KTX)

+ (BOOL) isKTX:(NSData*)data;

- (BOOL) loadKTX:(NSData*)data maxSize:(CGFloat)screens;

@end
