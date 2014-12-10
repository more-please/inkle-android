#pragma once

#import <Foundation/Foundation.h>

#import "AP_GLTexture.h"

// Loads a texture from a PNG file.
// Mipmaps are generated automatically.

@interface AP_GLTexture (PNG)

+ (BOOL) isPNG:(NSData*)data;

- (BOOL) loadPNG:(NSData*)data;

@end
