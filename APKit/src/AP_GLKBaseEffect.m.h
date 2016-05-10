// This file is included multiple times to generate GLKit shaders with various features.

#ifndef AP_GLKIT_SHADER
#error "AP_GLKIT_SHADER must be defined!"
#endif

#if AP_GLKIT_SHADER < 0 || AP_GLKIT_SHADER > 7
#error "AP_GLKIT_SHADER must be in the range 0-7"
#endif

// AP_GLKIT_SHADER is a bitmask controlling GLKit features, as follows:
#ifndef AP_GLKIT_SHADER_TEXCOORD0_MASK
#define AP_GLKIT_SHADER_TEXCOORD0_MASK 1
#define AP_GLKIT_SHADER_TEXCUBE_MASK 2
#define AP_GLKIT_SHADER_NORMAL_MASK 4
#endif

#undef _TEX       // True if we have texcoord0 attributes
#undef _TEX2D     // True if we have texcoord0 attributes and a 2D texture
#undef _TEXCUBE   // True if we have texcoord0 attributes and a cube texture
#undef _NORMAL    // True if we have normal attributes and light0 is enabled

#define _TEX ((AP_GLKIT_SHADER & AP_GLKIT_SHADER_TEXCOORD0_MASK) != 0)
#define _TEX2D (_TEX && (AP_GLKIT_SHADER & AP_GLKIT_SHADER_TEXCUBE_MASK) == 0)
#define _TEXCUBE (_TEX && (AP_GLKIT_SHADER & AP_GLKIT_SHADER_TEXCUBE_MASK) != 0)
#define _NORMAL ((AP_GLKIT_SHADER & AP_GLKIT_SHADER_NORMAL_MASK) != 0)

#undef IF_TEX
#undef IF_TEX2D
#undef IF_TEXCUBE
#undef IF_NORMAL

#if _TEX
#define IF_TEX(x) x
#else
#define IF_TEX(x)
#endif

#if _TEX2D
#define IF_TEX2D(x) x
#else
#define IF_TEX2D(x)
#endif

#if _TEXCUBE
#define IF_TEXCUBE(x) x
#else
#define IF_TEXCUBE(x)
#endif

#if _NORMAL
#define IF_NORMAL(x) x
#else
#define IF_NORMAL(x)
#endif

#undef IF_TEX_SHADER
#undef IF_TEX2D_SHADER
#undef IF_TEXCUBE_SHADER
#undef IF_NORMAL_SHADER

#define IF_TEX_SHADER(x)        IF_TEX(AP_SHADER(x))
#define IF_TEX2D_SHADER(x)      IF_TEX2D(AP_SHADER(x))
#define IF_TEXCUBE_SHADER(x)    IF_TEXCUBE(AP_SHADER(x))
#define IF_NORMAL_SHADER(x)     IF_NORMAL(AP_SHADER(x))

// -------------------------------------------------------------------------------------

#ifndef AP_GLKIT_SHADER_BASE_DEFINED
#define AP_GLKIT_SHADER_BASE_DEFINED

@interface AP_GLKit_Shader : AP_GLProgram {
@public
    GLint _modelviewMatrix;
    GLint _projectionMatrix;
    GLint _color;
}

- (void) prepareBaseEffect:(AP_GLKBaseEffect*)effect;

@end

@implementation AP_GLKit_Shader

- (BOOL) link
{
    if (![super link]) {
        return NO;
    }

    _modelviewMatrix = [self uniform:@"modelviewMatrix"];
    _projectionMatrix = [self uniform:@"projectionMatrix"];
    _color = [self uniform:@"color"];
    return YES;
}

- (void) prepareBaseEffect:(AP_GLKBaseEffect*)effect
{
    // Nothing
}

@end

#endif // AP_GLKIT_SHADER_BASE_DEFINED

// -------------------------------------------------------------------------------------

#ifndef AP_GLKIT_CONCAT
#define AP_GLKIT_CONCAT_(a,b) a ## b
#define AP_GLKIT_CONCAT(a,b) AP_GLKIT_CONCAT_(a,b)
#endif

#undef AP_GLKIT_SHADER_NAME
#define AP_GLKIT_SHADER_NAME AP_GLKIT_CONCAT(AP_GLKit_Shader_, AP_GLKIT_SHADER)

@interface AP_GLKIT_SHADER_NAME : AP_GLKit_Shader

- (instancetype) init;

@end

@implementation AP_GLKIT_SHADER_NAME {
    IF_TEX(
        GLint _texture;
    )
    IF_NORMAL(
        GLint _lightDirection;
        GLint _lightAmbient;
        GLint _lightDiffuse;
    )
}

- (instancetype) init
{
    static const char* kVertex = AP_SHADER(
        uniform mat4 modelviewMatrix;
        uniform mat4 projectionMatrix;
        attribute vec4 position;
    )
    IF_TEX2D_SHADER(
        attribute vec2 texCoord;
        varying vec2 fragTexCoord;
    )
    IF_TEXCUBE_SHADER(
        attribute vec3 texCoord;
        varying vec3 fragTexCoord;
    )
    IF_NORMAL_SHADER(
        attribute vec3 normal;
        varying vec3 fragNormal;
    )
    AP_SHADER(
        void main() {
            gl_Position = projectionMatrix * modelviewMatrix * position;
    )
    IF_TEX_SHADER(
            fragTexCoord = texCoord;
    )
    IF_NORMAL_SHADER(
            // TODO: should really use the 'normal matrix' here,
            // which is transpose(inverse(model)). However, this
            // will work as long as there's no non-linear scaling.
            fragNormal = normal; // (modelviewMatrix * vec4(normal, 1.0)).xyz;
    )
    AP_SHADER(
        }
    );

    static const char* kFragment = AP_SHADER(
        uniform vec4 color;
    )
    IF_TEX2D_SHADER(
        uniform sampler2D tex;
        varying vec2 fragTexCoord;
    )
    IF_TEXCUBE_SHADER(
        uniform samplerCube tex;
        varying vec3 fragTexCoord;
    )
    IF_NORMAL_SHADER(
        varying vec3 fragNormal;
        uniform vec3 lightDirection;
        uniform vec3 lightAmbient;
        uniform vec3 lightDiffuse;
    )
    AP_SHADER(
        void main() {
            vec4 c = color;
    )
    IF_TEX2D_SHADER(
            c = c * texture2D(tex, fragTexCoord);
    )
    IF_TEXCUBE_SHADER(
            c = c * textureCube(tex, fragTexCoord);
    )
    IF_NORMAL_SHADER(
            vec3 n = normalize(fragNormal);
            float intensity = clamp(dot(n, lightDirection), 0.0, 1.0);
            c = c * vec4(lightAmbient + lightDiffuse * intensity, 1.0);
    )
    AP_SHADER(
            gl_FragColor = c;
        }
    );

    return [super initWithVertex:kVertex fragment:kFragment];
}

- (BOOL) link
{
    _GL(BindAttribLocation, self.name, AP_GLKVertexAttribPosition, "position");
    IF_TEX(
        _GL(BindAttribLocation, self.name, AP_GLKVertexAttribTexCoord0, "texCoord");
    )
    IF_NORMAL(
        _GL(BindAttribLocation, self.name, AP_GLKVertexAttribNormal, "normal");
    )
    AP_CHECK_GL("Failed to bind GLKBaseEffect vertex attributes", return NO);
    
    if (![super link]) {
        return NO;
    }

    AP_CHECK([self attr:@"position"] == AP_GLKVertexAttribPosition, return NO);
    IF_TEX(
        AP_CHECK([self attr:@"texCoord"] == AP_GLKVertexAttribTexCoord0, return NO);
        _texture = [self uniform:@"tex"];
    )
    IF_NORMAL(
        AP_CHECK([self attr:@"normal"] == AP_GLKVertexAttribNormal, return NO);
        _lightDirection = [self uniform:@"lightDirection"];
        _lightAmbient = [self uniform:@"lightAmbient"];
        _lightDiffuse = [self uniform:@"lightDiffuse"];
    )
    return YES;
}

- (void) prepareBaseEffect:(AP_GLKBaseEffect*)effect
{
    [self use];

    IF_TEX(
        _GL(ActiveTexture, GL_TEXTURE0);
        _GL(Uniform1i, _texture, 0);
    )
    IF_TEX2D(
        _GL(BindTexture, GL_TEXTURE_2D, effect.texture.name);
    )
    IF_TEXCUBE(
        _GL(BindTexture, GL_TEXTURE_CUBE_MAP, effect.texture.name);
    )
    IF_NORMAL(
        AP_GLKEffectPropertyLight* light = effect.light0;
        AP_GLKEffectPropertyMaterial* material = effect.material;
        GLKVector4 lightDirection = light->_position; // Is this really right?
        GLKVector4 lightAmbient = GLKVector4Multiply(
            material.ambientColor,
            GLKVector4Add(effect.lightModelAmbientColor, light->_ambientColor));
        GLKVector4 lightDiffuse = GLKVector4Multiply(light->_diffuseColor, material->_diffuseColor);

        // Note: just discarding w field
        _GL(Uniform3fv, _lightDirection, 1, &lightDirection.v[0]);
        // Note: just discarding a fields
        _GL(Uniform3fv, _lightAmbient, 1, &lightAmbient.v[0]);
        _GL(Uniform3fv, _lightDiffuse, 1, &lightDiffuse.v[0]);
    )
}

@end

#undef AP_GLKIT_SHADER
