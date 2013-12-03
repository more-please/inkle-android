#import <GLKit/GLKit.h>

#ifdef AP_REPLACE_UI

#import "AP_GLKEffectPropertyTexture.h"
#import "AP_GLKEffectPropertyTransform.h"

// On some devices (I'm looking at you, Qualcomm) the attribute indices must be fully packed: we
// can't reserve any indices for unused attributes. Our renderer doesn't have "normal" or "color".
enum {
    AP_GLKVertexAttribPosition,
    // GLKVertexAttribNormal,
    // GLKVertexAttribColor,
    AP_GLKVertexAttribTexCoord0,
    // GLKVertexAttribTexCoord1
};

@interface AP_GLKBaseEffect : NSObject

@property (nonatomic, readonly) AP_GLKEffectPropertyTransform* transform; // Identity Matrices
@property (nonatomic, readonly) AP_GLKEffectPropertyTexture* texture2d0;
@property (nonatomic, assign) GLboolean useConstantColor; // GL_TRUE
@property (nonatomic, assign) GLKVector4 constantColor; // { 1.0, 1.0, 1.0, 1.0 }

- (void) prepareToDraw; // Bind programs and textures

@end

#else

#define AP_GLKVertexAttribPosition GLKVertexAttribPosition
#define AP_GLKVertexAttribTexCoord0 GLKVertexAttribTexCoord0

typedef GLKBaseEffect AP_GLKBaseEffect;

#endif
