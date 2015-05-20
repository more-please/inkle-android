#import "NSObject+AP_RoundRect.h"

#import "AP_Check.h"
#import "AP_GLBuffer.h"
#import "AP_GLProgram.h"
#import "AP_GLTexture.h"
#import "AP_Window.h"

@implementation NSObject (AP_RoundRect)

- (void) circleWithSize:(CGSize)size
    transform:(CGAffineTransform)transform
    color:(GLKVector4)color
{
    static AP_GLTexture* s_texture;
    static AP_GLProgram* s_prog;
    static GLint s_transform;
    static GLint s_color;
    static GLint s_pos;
    static GLint s_texPos;
    static GLint s_tex;

    static const char* kVertex = AP_SHADER(
        uniform mat3 transform;
        attribute vec3 pos;
        attribute vec2 texPos;
        varying vec2 f_texPos;

        void main() {
            gl_Position = vec4(transform * pos, 1.0);
            f_texPos = texPos;
        }
    );

    static const char* kFragment = AP_SHADER(
        uniform vec4 color;
        uniform sampler2D tex;
        varying vec2 f_texPos;

        void main() {
            float a = texture2D(tex, f_texPos).r;
            vec4 c = vec4(color.rgb, color.a * a);
            OUTPUT(c);
        }
    );

    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        s_texture = [AP_GLTexture textureNamed:@"circle_template.png" maxSize:4.0];
        s_prog = [[AP_GLProgram alloc] initWithVertex:kVertex fragment:kFragment];
        s_transform = [s_prog uniform:@"transform"];
        s_color = [s_prog uniform:@"color"];
        s_pos = [s_prog attr:@"pos"];
        s_texPos = [s_prog attr:@"texPos"];
        s_tex = [s_prog uniform:@"tex"];
    }

    AP_CHECK(s_texture, return);
    AP_CHECK(s_prog, return);

    GLKMatrix3 matrix = GLKMatrix3Make(
        transform.a * size.width,  transform.b * size.width,  0,
        transform.c * size.height, transform.d * size.height, 0,
        transform.tx,              transform.ty,              1);

    [s_prog use];

    _GL(Uniform4fv, s_color, 1, color.v);
    _GL(UniformMatrix3fv, s_transform, 1, false, matrix.m);

    const GLfloat a = 1/8.0, d = 7/8.0;
    GLfloat data[20] = {
        // pos.x, y, z, texPos.s, t
               0, 0, 1,        a, a,
               0, 1, 1,        a, d,
               1, 0, 1,        d, a,
               1, 1, 1,        d, d,
    };

    _GL(EnableVertexAttribArray, s_pos);
    _GL(VertexAttribPointer, s_pos, 3, GL_FLOAT, false, 5 * sizeof(GLfloat), &data[0]);

    _GL(EnableVertexAttribArray, s_texPos);
    _GL(VertexAttribPointer, s_texPos, 2, GL_FLOAT, false, 5 * sizeof(GLfloat), &data[3]);

    _GL(ActiveTexture, GL_TEXTURE0);
    _GL(Uniform1i, s_tex, 0);
    [s_texture bind];

    _GL(DrawArrays, GL_TRIANGLE_STRIP, 0, 4);

    _GL(DisableVertexAttribArray, s_pos);
    _GL(DisableVertexAttribArray, s_texPos);
}

- (void) rectWithSize:(CGSize)size
    transform:(CGAffineTransform)transform
    color:(GLKVector4)color
{
    static AP_GLTexture* s_texture;
    static AP_GLProgram* s_prog;
    static GLint s_transform;
    static GLint s_color;
    static GLint s_pos;
    static GLint s_texPos;
    static GLint s_tex;

    static const char* kVertex = AP_SHADER(
        uniform mat3 transform;
        attribute vec3 pos;
        attribute vec2 texPos;
        varying vec2 f_texPos;

        void main() {
            gl_Position = vec4(transform * pos, 1.0);
            f_texPos = texPos;
        }
    );

    static const char* kFragment = AP_SHADER(
        uniform vec4 color;
        uniform sampler2D tex;
        varying vec2 f_texPos;

        void main() {
            float a = texture2D(tex, f_texPos).r;
            vec4 c = vec4(color.rgb, color.a * a);
            OUTPUT(c);
        }
    );

    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        s_texture = [AP_GLTexture textureNamed:@"rect_template.png" maxSize:4.0];
        s_prog = [[AP_GLProgram alloc] initWithVertex:kVertex fragment:kFragment];
        s_transform = [s_prog uniform:@"transform"];
        s_color = [s_prog uniform:@"color"];
        s_pos = [s_prog attr:@"pos"];
        s_texPos = [s_prog attr:@"texPos"];
        s_tex = [s_prog uniform:@"tex"];
    }

    AP_CHECK(s_texture, return);
    AP_CHECK(s_prog, return);

    GLKMatrix3 matrix = GLKMatrix3Make(
        transform.a * size.width,  transform.b * size.width,  0,
        transform.c * size.height, transform.d * size.height, 0,
        transform.tx,              transform.ty,              1);

    [s_prog use];

    _GL(Uniform4fv, s_color, 1, color.v);
    _GL(UniformMatrix3fv, s_transform, 1, false, matrix.m);

    const GLfloat a = 1/8.0, d = 7/8.0;
    GLfloat data[20] = {
        // pos.x, y, z, texPos.s, t
               0, 0, 1,        a, a,
               0, 1, 1,        a, d,
               1, 0, 1,        d, a,
               1, 1, 1,        d, d,
    };

    _GL(EnableVertexAttribArray, s_pos);
    _GL(VertexAttribPointer, s_pos, 3, GL_FLOAT, false, 5 * sizeof(GLfloat), &data[0]);

    _GL(EnableVertexAttribArray, s_texPos);
    _GL(VertexAttribPointer, s_texPos, 2, GL_FLOAT, false, 5 * sizeof(GLfloat), &data[3]);

    _GL(ActiveTexture, GL_TEXTURE0);
    _GL(Uniform1i, s_tex, 0);
    [s_texture bind];

    _GL(DrawArrays, GL_TRIANGLE_STRIP, 0, 4);

    _GL(DisableVertexAttribArray, s_pos);
    _GL(DisableVertexAttribArray, s_texPos);
}

- (void) roundRectWithSize:(CGSize)size
    transform:(CGAffineTransform)transform
    color:(GLKVector4)color
    corner:(CGFloat)corner
{
    if (corner <= 0) {
        [self rectWithSize:size transform:transform color:color];
        return;
    }
    static AP_GLTexture* s_texture;
    static AP_GLProgram* s_prog;
    static GLint s_transform;
    static GLint s_color;
    static GLint s_pos;
    static GLint s_texPos;
    static GLint s_tex;

    static const char* kVertex = AP_SHADER(
        uniform mat3 transform;
        attribute vec3 pos;
        attribute vec2 texPos;
        varying vec2 f_texPos;

        void main() {
            gl_Position = vec4(transform * pos, 1.0);
            f_texPos = texPos;
        }
    );

    static const char* kFragment = AP_SHADER(
        uniform vec4 color;
        uniform sampler2D tex;
        varying vec2 f_texPos;

        void main() {
            float a = texture2D(tex, f_texPos).r;
            vec4 c = vec4(color.rgb, color.a * a);
            OUTPUT(c);
        }
    );

    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        s_texture = [AP_GLTexture textureNamed:@"round_rect_template.png" maxSize:4.0];
        s_prog = [[AP_GLProgram alloc] initWithVertex:kVertex fragment:kFragment];
        s_transform = [s_prog uniform:@"transform"];
        s_color = [s_prog uniform:@"color"];
        s_pos = [s_prog attr:@"pos"];
        s_texPos = [s_prog attr:@"texPos"];
        s_tex = [s_prog uniform:@"tex"];
    }

    AP_CHECK(s_texture, return);
    AP_CHECK(s_prog, return);

    CGSize screenSize = [AP_Window screenSize];
    CGFloat scale = [AP_Window screenScale];

    GLKMatrix3 matrix = GLKMatrix3Make(
        transform.a * size.width,  transform.b * size.width,  0,
        transform.c * size.height, transform.d * size.height, 0,
        transform.tx,              transform.ty,              1);

    [s_prog use];

    _GL(Uniform4fv, s_color, 1, color.v);
    _GL(UniformMatrix3fv, s_transform, 1, false, matrix.m);

    const GLfloat kx = corner / size.width;
    const GLfloat ky = corner / size.height;
    const GLfloat a = 1/8.0, b = 3/8.0, c = 5/8.0, d = 7/8.0;
    GLfloat data[80] = {
        // pos.x, y, z, texPos.s, t
               0, 0, 1,        a, a,
              kx, 0, 1,        b, a,
            1-kx, 0, 1,        c, a,
               1, 0, 1,        d, a,

               0, ky, 1,       a, b,
              kx, ky, 1,       b, b,
            1-kx, ky, 1,       c, b,
               1, ky, 1,       d, b,

               0, 1-ky, 1,     a, c,
              kx, 1-ky, 1,     b, c,
            1-kx, 1-ky, 1,     c, c,
               1, 1-ky, 1,     d, c,

               0, 1, 1,        a, d,
              kx, 1, 1,        b, d,
            1-kx, 1, 1,        c, d,
               1, 1, 1,        d, d,
    };

    _GL(EnableVertexAttribArray, s_pos);
    _GL(VertexAttribPointer, s_pos, 3, GL_FLOAT, false, 5 * sizeof(GLfloat), &data[0]);

    _GL(EnableVertexAttribArray, s_texPos);
    _GL(VertexAttribPointer, s_texPos, 2, GL_FLOAT, false, 5 * sizeof(GLfloat), &data[3]);

    _GL(ActiveTexture, GL_TEXTURE0);
    _GL(Uniform1i, s_tex, 0);
    [s_texture bind];

    GLubyte indices[22] = {
         0, 4,
         1, 5,  2,  6,  3,  7,
        11, 6, 10,  5,  9,  4, 8,
        12, 9, 13, 10, 14, 11, 15
    };

    _GL(DrawElements, GL_TRIANGLE_STRIP, 22, GL_UNSIGNED_BYTE, indices);

    _GL(DisableVertexAttribArray, s_pos);
    _GL(DisableVertexAttribArray, s_texPos);
}

- (void) roundRectWithSize:(CGSize)size
    transform:(CGAffineTransform)transform
    penColor:(GLKVector4)penColor
    fillColor:(GLKVector4)fillColor
    pen:(CGFloat)pen
    corner:(CGFloat)corner
{
    if (pen <= 0 && corner <= 0) {
        [self rectWithSize:size transform:transform color:fillColor];
        return;
    }
    if (pen <= 0) {
        [self roundRectWithSize:size transform:transform color:fillColor corner:corner];
        return;
    }
    NSAssert((pen + 1) < corner, @"pen size must be lower than corner size");

    static AP_GLTexture* s_texture;
    static AP_GLProgram* s_prog;
    static GLint s_transform;
    static GLint s_penColor;
    static GLint s_fillColor;
    static GLint s_pos;
    static GLint s_penTexPos;
    static GLint s_fillTexPos;
    static GLint s_tex;

    static const char* kVertex = AP_SHADER(
        uniform mat3 transform;
        attribute vec3 pos;
        attribute vec2 penTexPos;
        attribute vec2 fillTexPos;
        varying vec2 f_penTexPos;
        varying vec2 f_fillTexPos;

        void main() {
            gl_Position = vec4(transform * pos, 1.0);
            f_penTexPos = penTexPos;
            f_fillTexPos = fillTexPos;
        }
    );

    static const char* kFragment = AP_SHADER(
        uniform vec4 penColor;
        uniform vec4 fillColor;
        uniform sampler2D tex;
        varying vec2 f_penTexPos;
        varying vec2 f_fillTexPos;

        void main() {
            float p = texture2D(tex, f_penTexPos).r;
            float f = texture2D(tex, f_fillTexPos).r;
            vec4 color = mix(penColor, fillColor, f);
            vec4 c = vec4(color.rgb, color.a * p);
            OUTPUT(c);
        }
    );

    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        s_texture = [AP_GLTexture textureNamed:@"round_rect_template.png" maxSize:4.0];
        s_prog = [[AP_GLProgram alloc] initWithVertex:kVertex fragment:kFragment];
        s_transform = [s_prog uniform:@"transform"];
        s_penColor = [s_prog uniform:@"penColor"];
        s_fillColor = [s_prog uniform:@"fillColor"];
        s_pos = [s_prog attr:@"pos"];
        s_penTexPos = [s_prog attr:@"penTexPos"];
        s_fillTexPos = [s_prog attr:@"fillTexPos"];
        s_tex = [s_prog uniform:@"tex"];
    }

    AP_CHECK(s_texture, return);
    AP_CHECK(s_prog, return);

    CGSize screenSize = [AP_Window screenSize];
    CGFloat scale = [AP_Window screenScale];

    GLKMatrix3 matrix = GLKMatrix3Make(
        transform.a * size.width,  transform.b * size.width,  0,
        transform.c * size.height, transform.d * size.height, 0,
        transform.tx,              transform.ty,              1);

    [s_prog use];

    _GL(Uniform4fv, s_penColor, 1, penColor.v);
    _GL(Uniform4fv, s_fillColor, 1, fillColor.v);
    _GL(UniformMatrix3fv, s_transform, 1, false, matrix.m);

    const GLfloat kx = corner / size.width;
    const GLfloat ky = corner / size.height;
    const GLfloat a = 1/8.0, b = 3/8.0, c = 5/8.0, d = 7/8.0;
    const GLfloat p = corner / (corner - pen) - 1.0;
    const GLfloat _a = a - p/4;
    const GLfloat _d = d + p/4;
    GLfloat data[112] = {
        // pos.x, y, z, penTexPos.s, t, fillTexPos.s,  t
               0, 0, 1,           a, a,           _a, _a,
              kx, 0, 1,           b, a,            b, _a,
            1-kx, 0, 1,           c, a,            c, _a,
               1, 0, 1,           d, a,           _d, _a,

               0, ky, 1,          a, b,           _a,  b,
              kx, ky, 1,          b, b,            b,  b,
            1-kx, ky, 1,          c, b,            c,  b,
               1, ky, 1,          d, b,           _d,  b,

               0, 1-ky, 1,        a, c,           _a,  c,
              kx, 1-ky, 1,        b, c,            b,  c,
            1-kx, 1-ky, 1,        c, c,            c,  c,
               1, 1-ky, 1,        d, c,           _d,  c,

               0, 1, 1,           a, d,           _a, _d,
              kx, 1, 1,           b, d,            b, _d,
            1-kx, 1, 1,           c, d,            c, _d,
               1, 1, 1,           d, d,           _d, _d,
    };

    _GL(EnableVertexAttribArray, s_pos);
    _GL(VertexAttribPointer, s_pos, 3, GL_FLOAT, false, 7 * sizeof(GLfloat), &data[0]);

    _GL(EnableVertexAttribArray, s_penTexPos);
    _GL(VertexAttribPointer, s_penTexPos, 2, GL_FLOAT, false, 7 * sizeof(GLfloat), &data[3]);

    _GL(EnableVertexAttribArray, s_fillTexPos);
    _GL(VertexAttribPointer, s_fillTexPos, 2, GL_FLOAT, false, 7 * sizeof(GLfloat), &data[5]);

    _GL(ActiveTexture, GL_TEXTURE0);
    _GL(Uniform1i, s_tex, 0);
    [s_texture bind];

    GLubyte indices[22] = {
         0, 4,
         1, 5,  2,  6,  3,  7,
        11, 6, 10,  5,  9,  4, 8,
        12, 9, 13, 10, 14, 11, 15
    };

    _GL(DrawElements, GL_TRIANGLE_STRIP, 22, GL_UNSIGNED_BYTE, indices);

    _GL(DisableVertexAttribArray, s_pos);
    _GL(DisableVertexAttribArray, s_penTexPos);
    _GL(DisableVertexAttribArray, s_fillTexPos);
}

@end
