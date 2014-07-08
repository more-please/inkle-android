#pragma once

#import <Foundation/Foundation.h>

#import "AP_GLTexture.h"

// Loads a compressed texture from a KTX file.
// Does not check whether the texture is supported by the current hardware.

@interface AP_GLTexture_KTX : AP_GLTexture

- (AP_GLTexture_KTX*) initWithData:(NSData*)data maxSize:(CGFloat)screens;

+ (BOOL) isKTX:(NSData*)data;
+ (AP_GLTexture*) withData:(NSData*)data maxSize:(CGFloat)screens;

@end
