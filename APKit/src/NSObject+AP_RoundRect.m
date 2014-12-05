#import "NSObject+AP_RoundRect.h"

#import "AP_Check.h"
#import "AP_GLBuffer.h"
#import "AP_GLProgram.h"
#import "AP_Window.h"

static const char* kCommonVertex = AP_SHADER(
    uniform vec2 screenSize;
    uniform mat3 transform;
    attribute vec3 pos;
    varying vec2 f_innerPos;
    varying vec2 f_outerPos;

    void main() {
        gl_Position = vec4(transform * pos, 1.0);
        // Calculate two positions roughly one pixel apart, for anti-aliasing
        vec3 dx = vec3(0.5, 0.0, 0.0);
        vec3 dy = vec3(0.0, 0.5, 0.0);
        vec2 xScreen = (transform * (pos + dx) - transform * (pos - dx)).xy;
        vec2 yScreen = (transform * (pos + dy) - transform * (pos - dy)).xy;
        float xPix = length(xScreen * 0.5 * screenSize);
        float yPix = length(yScreen * 0.5 * screenSize);
        vec2 p = pos.xy - 0.5;
        vec2 k = p / vec2(xPix, yPix);
        f_innerPos = p - k;
        f_outerPos = p + k;
    }
);

static const char* kCircleFragment = AP_SHADER(
    uniform vec4 color;
    varying vec2 f_innerPos;
    varying vec2 f_outerPos;

    float distanceForPoint(vec2 p) {
        return length(p);
    }

    float alphaForDistances(float inner, float outer) {
        float lo = min(inner, outer);
        float hi = max(inner, outer);
        return clamp((0.5 - lo) / (hi - lo), 0.0, 1.0);
    }

    float alphaForEdge(vec2 inner, vec2 outer) {
        return alphaForDistances(distanceForPoint(inner), distanceForPoint(outer));
    }

    void main() {
        float a = alphaForEdge(f_innerPos, f_outerPos);
        gl_FragColor = vec4(color.rgb, color.a * a);
    }
);

static const char* kRoundRectFragment = AP_SHADER(
    uniform vec4 fillColor;
    uniform vec4 penColor;
    uniform vec2 corner;
    uniform vec2 pen;

    varying vec2 f_outerPos;
    varying vec2 f_innerPos;

    const vec2 zero = vec2(0.0, 0.0);

    float alphaForDistances(float inner, float outer) {
        float lo = min(inner, outer);
        float hi = max(inner, outer);
        return clamp((0.5 - lo) / (hi - lo), 0.0, 1.0);
    }

    vec2 focus(vec2 c) {
        vec2 c2 = c * c;
        return sqrt(max(zero, vec2(c2.x - c2.y, c2.y - c2.x)));
    }

    float distanceForPoint(vec2 p) {
        p = abs(p) - 0.5 + corner;
        vec2 f = focus(corner);
        vec2 pLo = min(p - f, zero);
        vec2 pHi = max(p, zero);
        float rectDist = max(pLo.x, pLo.y);
        float ellipseDist = 0.5 * (distance(pHi, f) + distance(pHi, -f)) - max(corner.x, corner.y);
        return 0.5 + rectDist + ellipseDist;
    }

    float distanceForPointWithPen(vec2 p) {
        vec2 innerCorner = max(zero, corner - pen);
        p = abs(p) - 0.5 + innerCorner + pen;
        vec2 f = focus(innerCorner);
        vec2 pLo = min(p - f, zero);
        vec2 pHi = max(p, zero);
        float rectDist = max(pLo.x, pLo.y);
        float ellipseDist = 0.5 * (distance(pHi, f) + distance(pHi, -f)) - max(innerCorner.x, innerCorner.y);
        return 0.5 + rectDist + ellipseDist;
    }

    float alphaForEdge(vec2 inner, vec2 outer) {
        return alphaForDistances(distanceForPoint(inner), distanceForPoint(outer));
    }

    float alphaForEdgeWithPen(vec2 inner, vec2 outer) {
        return alphaForDistances(distanceForPointWithPen(inner), distanceForPointWithPen(outer));
    }

    void main() {
        float a1 = alphaForEdge(f_innerPos, f_outerPos);
        float a2 = alphaForEdgeWithPen(f_innerPos, f_outerPos);
        vec4 ink = mix(penColor, fillColor, a2);
        gl_FragColor = vec4(ink.rgb, ink.a * a1);
    }
);

static const char* kRectFragment = AP_SHADER(
    uniform vec4 color;
    void main() {
        gl_FragColor = color;
    }
);

@implementation NSObject (AP_RoundRect)

- (void) circleWithSize:(CGSize)size
    transform:(CGAffineTransform)transform
    color:(GLKVector4)color
{
    static AP_GLProgram* s_prog;
    static AP_GLBuffer* s_buffer;
    static GLint s_screenSize;
    static GLint s_transform;
    static GLint s_color;
    static GLint s_pos;

    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        s_prog = [[AP_GLProgram alloc] initWithVertex:kCommonVertex fragment:kCircleFragment];
        s_screenSize = [s_prog uniform:@"screenSize"];
        s_transform = [s_prog uniform:@"transform"];
        s_color = [s_prog uniform:@"color"];
        s_pos = [s_prog attr:@"pos"];

        s_buffer = [[AP_GLBuffer alloc] init];
        [s_buffer bind];

        // Unit square around (0.5,0.5) in homogenous 2D coordinates
        float k = 0.01; // Outset slightly to avoid gaps at the edges.
        float data[12] = {
            0-k, 0-k, 1,
            0-k, 1+k, 1,
            1+k, 0-k, 1,
            1+k, 1+k, 1,
        };
        [s_buffer bufferTarget:GL_ARRAY_BUFFER usage:GL_STATIC_DRAW data:data size:sizeof(data)];
    }

    AP_CHECK(s_prog, return);
    AP_CHECK(s_buffer, return);

    CGSize screenSize = [AP_Window screenSize];
    CGFloat scale = [AP_Window screenScale];

    GLKMatrix3 matrix = GLKMatrix3Make(
        transform.a * size.width,  transform.b * size.width,  0,
        transform.c * size.height, transform.d * size.height, 0,
        transform.tx,              transform.ty,              1);

    [s_buffer bind];
    [s_prog use];

    _GL(Uniform4fv, s_color, 1, color.v);
    _GL(Uniform2f, s_screenSize, screenSize.width * scale, screenSize.height * scale);
    _GL(UniformMatrix3fv, s_transform, 1, false, matrix.m);
    _GL(EnableVertexAttribArray, s_pos);
    _GL(VertexAttribPointer, s_pos, 3, GL_FLOAT, false, 0, 0);

    _GL(DrawArrays, GL_TRIANGLE_STRIP, 0, 4);

    _GL(DisableVertexAttribArray, s_pos);

    [s_buffer unbind];
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

    static AP_GLProgram* s_prog;
    static AP_GLBuffer* s_buffer;
    static GLint s_screenSize;
    static GLint s_transform;
    static GLint s_fillColor;
    static GLint s_penColor;
    static GLint s_corner;
    static GLint s_pen;
    static GLint s_pos;

    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        s_prog = [[AP_GLProgram alloc] initWithVertex:kCommonVertex fragment:kRoundRectFragment];
        s_screenSize = [s_prog uniform:@"screenSize"];
        s_transform = [s_prog uniform:@"transform"];
        s_fillColor = [s_prog uniform:@"fillColor"];
        s_penColor = [s_prog uniform:@"penColor"];
        s_corner = [s_prog uniform:@"corner"];
        s_pen = [s_prog uniform:@"pen"];
        s_pos = [s_prog attr:@"pos"];

        s_buffer = [[AP_GLBuffer alloc] init];
        [s_buffer bind];

        // Unit square around (0.5,0.5) in homogenous 2D coordinates
        float k = 0.01; // Outset slightly to avoid gaps at the edges.
        float data[12] = {
            0-k, 0-k, 1,
            0-k, 1+k, 1,
            1+k, 0-k, 1,
            1+k, 1+k, 1,
        };
        [s_buffer bufferTarget:GL_ARRAY_BUFFER usage:GL_STATIC_DRAW data:data size:sizeof(data)];
    }

    AP_CHECK(s_prog, return);
    AP_CHECK(s_buffer, return);

    CGSize screenSize = [AP_Window screenSize];
    CGFloat scale = [AP_Window screenScale];

    GLKMatrix3 matrix = GLKMatrix3Make(
        transform.a * size.width,  transform.b * size.width,  0,
        transform.c * size.height, transform.d * size.height, 0,
        transform.tx,              transform.ty,              1);

    [s_buffer bind];
    [s_prog use];

    _GL(Uniform4fv, s_fillColor, 1, fillColor.v);
    _GL(Uniform4fv, s_penColor, 1, penColor.v);
    _GL(Uniform2f, s_corner, corner / size.width, corner / size.height);
    _GL(Uniform2f, s_pen, pen / size.width, pen / size.height);
    _GL(Uniform2f, s_screenSize, screenSize.width * scale, screenSize.height * scale);
    _GL(UniformMatrix3fv, s_transform, 1, false, matrix.m);
    _GL(EnableVertexAttribArray, s_pos);
    _GL(VertexAttribPointer, s_pos, 3, GL_FLOAT, false, 0, 0);

    _GL(DrawArrays, GL_TRIANGLE_STRIP, 0, 4);

    _GL(DisableVertexAttribArray, s_pos);

    [s_buffer unbind];
}

- (void) rectWithSize:(CGSize)size
    transform:(CGAffineTransform)transform
    color:(GLKVector4)color
{
    static AP_GLProgram* s_prog;
    static AP_GLBuffer* s_buffer;
    static GLint s_screenSize;
    static GLint s_transform;
    static GLint s_color;
    static GLint s_pos;

    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        s_prog = [[AP_GLProgram alloc] initWithVertex:kCommonVertex fragment:kRectFragment];
        s_screenSize = [s_prog uniform:@"screenSize"];
        s_transform = [s_prog uniform:@"transform"];
        s_color = [s_prog uniform:@"color"];
        s_pos = [s_prog attr:@"pos"];

        s_buffer = [[AP_GLBuffer alloc] init];
        [s_buffer bind];

        // Unit square around (0.5,0.5) in homogenous 2D coordinates
        float data[12] = {
            0, 0, 1,
            0, 1, 1,
            1, 0, 1,
            1, 1, 1,
        };
        [s_buffer bufferTarget:GL_ARRAY_BUFFER usage:GL_STATIC_DRAW data:data size:sizeof(data)];
    }

    AP_CHECK(s_prog, return);
    AP_CHECK(s_buffer, return);

    CGSize screenSize = [AP_Window screenSize];
    CGFloat scale = [AP_Window screenScale];

    GLKMatrix3 matrix = GLKMatrix3Make(
        transform.a * size.width,  transform.b * size.width,  0,
        transform.c * size.height, transform.d * size.height, 0,
        transform.tx,              transform.ty,              1);

    [s_buffer bind];
    [s_prog use];

    _GL(Uniform4fv, s_color, 1, color.v);
    _GL(Uniform2f, s_screenSize, screenSize.width * scale, screenSize.height * scale);
    _GL(UniformMatrix3fv, s_transform, 1, false, matrix.m);
    _GL(EnableVertexAttribArray, s_pos);
    _GL(VertexAttribPointer, s_pos, 3, GL_FLOAT, false, 0, 0);

    _GL(DrawArrays, GL_TRIANGLE_STRIP, 0, 4);

    _GL(DisableVertexAttribArray, s_pos);

    [s_buffer unbind];
}

@end
