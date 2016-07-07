#pragma once

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#import "AP_GLTexture.h"
#import "AP_GLKEffectPropertyLight.h"
#import "AP_GLKEffectPropertyMaterial.h"
#import "AP_GLKEffectPropertyTransform.h"

// On some devices (I'm looking at you, Qualcomm) the attribute indices must be fully packed: we
// can't reserve any indices for unused attributes. We therefore reshuffle the indices to avoid
// gaps (e.g. 'normal' isn't always used so it goes at the end).
enum {
    AP_GLKVertexAttribPosition,
    AP_GLKVertexAttribTexCoord0,
    AP_GLKVertexAttribNormal,
    // AP_GLKVertexAttribColor,
    // GLKVertexAttribTexCoord1
};

typedef enum AP_GLKLightingType {
    AP_GLKLightingTypePerVertex,
    AP_GLKLightingTypePerPixel
} AP_GLKLightingType;

@interface AP_GLKBaseEffect : NSObject

@property (nonatomic, readonly) AP_GLKEffectPropertyTransform* transform; // Identity Matrices
@property (nonatomic, readonly) AP_GLKEffectPropertyLight* light0;
@property (nonatomic, readonly) AP_GLKEffectPropertyMaterial* material;
@property (nonatomic, assign) AP_GLKLightingType lightingType; // GLKLightingTypePerVertex
@property (nonatomic, assign) GLKVector4 lightModelAmbientColor; // { 0.2, 0.2, 0.2, 1.0 }
@property (nonatomic, strong) AP_GLTexture* texture;
@property (nonatomic) GLboolean useConstantColor; // GL_TRUE
@property (nonatomic) GLKVector4 constantColor; // { 1.0, 1.0, 1.0, 1.0 }

// Iain hack
@property (nonatomic) GLboolean useRGBK; // GL_FALSE

- (void) prepareToDraw; // Bind programs and textures

// Android alpha hack: instead of rendering GLKViews to an offscreen
// buffer and alpha-blending that to the screen, we just render GL
// content directly to the screen. We therefore need to draw *every*
// GL element with the alpha of the containing view. (This won't look
// quite right for layered content, but in practice it isn't a big
// problem.)
@property (nonatomic) GLfloat alpha;

@end
