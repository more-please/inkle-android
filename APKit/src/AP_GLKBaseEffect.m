#import "AP_GLKBaseEffect.h"

#import "AP_Check.h"
#import "AP_GLProgram.h"

@interface AP_GLKBaseEffect_Program : AP_GLProgram
@end

@implementation AP_GLKBaseEffect_Program

- (BOOL) link
{
    _GL(BindAttribLocation, self.name, AP_GLKVertexAttribPosition, "position");
    _GL(BindAttribLocation, self.name, AP_GLKVertexAttribTexCoord0, "texCoord0");
    AP_CHECK_GL("Failed to bind GLKBaseEffect vertex attributes", return NO);
    
    if (![super link]) {
        return NO;
    }

    AP_CHECK([self attr:@"position"] == AP_GLKVertexAttribPosition, return NO);
    AP_CHECK([self attr:@"texCoord0"] == AP_GLKVertexAttribTexCoord0, return NO);
    return YES;
}

@end

@implementation AP_GLKBaseEffect

- (id) init
{
    self = [super init];
    if (self) {
        _texture2d0 = [[AP_GLKEffectPropertyTexture alloc] init];
        _transform = [[AP_GLKEffectPropertyTransform alloc] init];
        _useConstantColor = GL_TRUE;
        _constantColor = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
    }
    return self;
}

- (void) prepareToDraw
{
    static const char* kVertex = AP_SHADER(
        uniform mat4 modelViewProjectionMatrix;
        attribute vec4 position;
        attribute vec2 texCoord0;
        varying vec2 fragTexCoord;
        void main() {
            gl_Position = modelViewProjectionMatrix * position;
            fragTexCoord = texCoord0;
        }
    );

    static const char* kFragment = AP_SHADER(
        uniform vec4 color;
        uniform sampler2D tex;
        varying vec2 fragTexCoord;
        void main() {
            gl_FragColor = color * texture2D(tex, fragTexCoord);
        }
    );

    static AP_GLKBaseEffect_Program* prog;
    static GLint modelViewProjectionMatrix;
    static GLint texture;
    static GLint color;

    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        prog = [[AP_GLKBaseEffect_Program alloc] initWithVertex:kVertex fragment:kFragment];
        modelViewProjectionMatrix = [prog uniform:@"modelViewProjectionMatrix"];
        texture = [prog uniform:@"tex"];
        color = [prog uniform:@"color"];
    }

    AP_CHECK(prog, return);

    [prog use];

    _GL(ActiveTexture, GL_TEXTURE0);
    _GL(BindTexture, GL_TEXTURE_2D, _texture2d0.enabled ? _texture2d0.name : 0);
    _GL(Uniform1i, texture, 0);
    GLKVector4 c = {1, 1, 1, 1};
    if (_useConstantColor) {
        c = _constantColor;
    }
    c.a *= _alpha;
    _GL(Uniform4fv, color, 1, &c.v[0]);

    GLKMatrix4 modelViewProjection = GLKMatrix4Multiply(_transform.projectionMatrix, _transform.modelviewMatrix);
    _GL(UniformMatrix4fv, modelViewProjectionMatrix, 1, NO, modelViewProjection.m);

    _GL(BindBuffer, GL_ARRAY_BUFFER, 0);
    _GL(BindBuffer, GL_ELEMENT_ARRAY_BUFFER, 0);
}

@end
