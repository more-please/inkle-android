#pragma once

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>

#ifdef AP_REPLACE_UI

@interface AP_GLKEffectPropertyTexture : NSObject

@property (nonatomic) GLuint name;

@end

#else
typedef GLKEffectPropertyTexture AP_GLKEffectPropertyTexture;
#endif
