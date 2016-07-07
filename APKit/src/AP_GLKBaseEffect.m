#import "AP_GLKBaseEffect.h"

#import "AP_Check.h"
#import "AP_GLProgram.h"

// ----------------------------------------------------------------------------
// Preprocessor hack... Define a class for each combination of shader features!

#define AP_GLKIT_SHADER 0
#include "AP_GLKBaseEffect.m.h"

#define AP_GLKIT_SHADER 1
#include "AP_GLKBaseEffect.m.h"

#define AP_GLKIT_SHADER 2
#include "AP_GLKBaseEffect.m.h"

#define AP_GLKIT_SHADER 3
#include "AP_GLKBaseEffect.m.h"

#define AP_GLKIT_SHADER 4
#include "AP_GLKBaseEffect.m.h"

#define AP_GLKIT_SHADER 5
#include "AP_GLKBaseEffect.m.h"

#define AP_GLKIT_SHADER 6
#include "AP_GLKBaseEffect.m.h"

#define AP_GLKIT_SHADER 7
#include "AP_GLKBaseEffect.m.h"

#define AP_GLKIT_SHADER 8
#include "AP_GLKBaseEffect.m.h"

#define AP_GLKIT_SHADER 9
#include "AP_GLKBaseEffect.m.h"

#define AP_GLKIT_SHADER 10
#include "AP_GLKBaseEffect.m.h"

#define AP_GLKIT_SHADER 11
#include "AP_GLKBaseEffect.m.h"

#define AP_GLKIT_SHADER 12
#include "AP_GLKBaseEffect.m.h"

#define AP_GLKIT_SHADER 13
#include "AP_GLKBaseEffect.m.h"

#define AP_GLKIT_SHADER 14
#include "AP_GLKBaseEffect.m.h"

#define AP_GLKIT_SHADER 15
#include "AP_GLKBaseEffect.m.h"

static AP_GLKit_Shader* _shaders[16];

// ----------------------------------------------------------------------------

@implementation AP_GLKBaseEffect

+ (void) initialize
{
    _shaders[0] = [[AP_GLKit_Shader_0 alloc] init];
    _shaders[1] = [[AP_GLKit_Shader_1 alloc] init];
    _shaders[2] = [[AP_GLKit_Shader_2 alloc] init];
    _shaders[3] = [[AP_GLKit_Shader_3 alloc] init];
    _shaders[4] = [[AP_GLKit_Shader_4 alloc] init];
    _shaders[5] = [[AP_GLKit_Shader_5 alloc] init];
    _shaders[6] = [[AP_GLKit_Shader_6 alloc] init];
    _shaders[7] = [[AP_GLKit_Shader_7 alloc] init];
    _shaders[8] = [[AP_GLKit_Shader_8 alloc] init];
    _shaders[9] = [[AP_GLKit_Shader_9 alloc] init];
    _shaders[10] = [[AP_GLKit_Shader_10 alloc] init];
    _shaders[11] = [[AP_GLKit_Shader_11 alloc] init];
    _shaders[12] = [[AP_GLKit_Shader_12 alloc] init];
    _shaders[13] = [[AP_GLKit_Shader_13 alloc] init];
    _shaders[14] = [[AP_GLKit_Shader_14 alloc] init];
    _shaders[15] = [[AP_GLKit_Shader_15 alloc] init];
}

- (id) init
{
    self = [super init];
    if (self) {
        _transform = [[AP_GLKEffectPropertyTransform alloc] init];
        _light0 = [[AP_GLKEffectPropertyLight alloc] init];
        _lightModelAmbientColor = GLKVector4Make(0.2, 0.2, 0.2, 1);
        _material = [[AP_GLKEffectPropertyMaterial alloc] init];
        _useConstantColor = GL_TRUE;
        _constantColor = GLKVector4Make(1, 1, 1, 1);
    }
    return self;
}

- (void) prepareToDraw
{
    int n = 0;
    if (_texture) {
        n |= AP_GLKIT_SHADER_TEXCOORD0_MASK;
        if (_texture.cube) {
            n |= AP_GLKIT_SHADER_TEXCUBE_MASK;
        }
    }
    if (_light0.enabled) {
        n |= AP_GLKIT_SHADER_NORMAL_MASK;
    }
    if (_useRGBK) {
        n |= AP_GLKIT_SHADER_RGBK_MASK;
    }

    AP_GLKit_Shader* shader = _shaders[n];
    AP_CHECK(shader, return);

    [shader prepareBaseEffect:self];

    GLKVector4 c = {1, 1, 1, 1};
    if (_useConstantColor) {
        c = _constantColor;
    }
    c.a *= _alpha;
    _GL(Uniform4fv, shader->_color, 1, &c.v[0]);

    _GL(UniformMatrix4fv, shader->_modelviewMatrix, 1, NO, _transform->_modelviewMatrix.m);
    _GL(UniformMatrix4fv, shader->_projectionMatrix, 1, NO, _transform->_projectionMatrix.m);

    _GL(BindBuffer, GL_ARRAY_BUFFER, 0);
    _GL(BindBuffer, GL_ELEMENT_ARRAY_BUFFER, 0);
}

@end
