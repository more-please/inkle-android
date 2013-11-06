#import <GLKit/GLKit.h>

#ifdef AP_REPLACE_UI

#import "AP_GLKEffectPropertyTexture.h"
#import "AP_GLKEffectPropertyTransform.h"

@interface AP_GLKBaseEffect : NSObject

@property (nonatomic, readonly) AP_GLKEffectPropertyTransform* transform; // Identity Matrices
@property (nonatomic, readonly) AP_GLKEffectPropertyTexture* texture2d0;
@property (nonatomic, assign) GLboolean useConstantColor; // GL_TRUE
@property (nonatomic, assign) GLKVector4 constantColor; // { 1.0, 1.0, 1.0, 1.0 }

- (void) prepareToDraw; // Bind programs and textures

@end

#else
typedef GLKBaseEffect AP_GLKBaseEffect;
#endif
