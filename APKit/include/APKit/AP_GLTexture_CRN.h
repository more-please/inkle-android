#pragma once

#ifdef SORCERY_SDL

#import <Foundation/Foundation.h>

#import "AP_GLTexture.h"

// Loads a compressed texture from a CRN file.
// Does not check whether the texture is supported by the current hardware.

@interface AP_GLTexture (CRN)

+ (BOOL) isCRN:(NSData*)data;

- (BOOL) loadCRN:(NSData*)data maxSize:(CGFloat)screens;

@end

#endif // SORCERY_SDL
