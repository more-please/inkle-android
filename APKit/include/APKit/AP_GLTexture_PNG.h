#pragma once

#import <Foundation/Foundation.h>

#import "AP_GLTexture.h"

// Loads a texture from a PNG file.
// Mipmaps are generated automatically.

@interface AP_GLTexture_PNG : AP_GLTexture

- (AP_GLTexture_PNG*) initWithData:(NSData*)data;

+ (BOOL) isPNG:(NSData*)data;
+ (AP_GLTexture*) withData:(NSData*)data;

@end
