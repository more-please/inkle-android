#pragma once

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#import "AP_GLTexture.h"
#import "AP_GLKEffectPropertyTransform.h"

// On some devices (I'm looking at you, Qualcomm) the attribute indices must be fully packed: we
// can't reserve any indices for unused attributes. Our renderer doesn't have "normal" or "color".
enum {
    AP_GLKVertexAttribPosition,
    // GLKVertexAttribNormal,
    // AP_GLKVertexAttribColor,
    AP_GLKVertexAttribTexCoord0,
    // GLKVertexAttribTexCoord1
};

@interface AP_GLKBaseEffect : NSObject

@property (nonatomic, strong, readonly) AP_GLKEffectPropertyTransform* transform; // Identity Matrices
@property (nonatomic, strong) AP_GLTexture* texture;
@property (nonatomic) GLboolean useConstantColor; // GL_TRUE
@property (nonatomic) GLKVector4 constantColor; // { 1.0, 1.0, 1.0, 1.0 }

- (void) prepareToDraw; // Bind programs and textures

// Android alpha hack: instead of rendering GLKViews to an offscreen
// buffer and alpha-blending that to the screen, we just render GL
// content directly to the screen. We therefore need to draw *every*
// GL element with the alpha of the containing view. (This won't look
// quite right for layered content, but in practice it isn't a big
// problem.)
@property (nonatomic) GLfloat alpha;

// Iain addition: hack to extract the final transform (calculated in prepareToDraw)
@property (nonatomic, readonly) GLKMatrix4 modelViewProjectionMatrix;

@end
