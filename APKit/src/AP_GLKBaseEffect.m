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

static AP_GLKit_Shader* _shaders[8];

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
