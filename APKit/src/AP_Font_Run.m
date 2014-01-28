#import "AP_Font_Run.h"

#import <GLKit/GLKit.h>

#import "AP_Check.h"
#import "AP_Font_Data.h"
#import "AP_GLBuffer.h"
#import "AP_GLProgram.h"
#import "AP_Utils.h"

@implementation AP_Font_Run {
    
    AP_GLBuffer* _arrayBuffer;
    AP_GLBuffer* _indexBuffer;
    GLKVector4 _textColor;

    AP_Font_Data* _fontData;
    NSData* _runData;
    unsigned char* _glyphs;
    float* _positions; // Contains one extra value, with the position after the final char.

    // Subset of the run that we actually draw (half-open interval, so length = end - start).
    int _start;
    int _end;
}

- (int) start { return _start; }
- (int) end { return _end; }

typedef struct VertexData {
    GLfloat x, y;
    GLfloat xTex, yTex;
} VertexData;

- (AP_Font_Run*) initWithRun:(AP_Font_Run*)run start:(int)start end:(int)end
{
    self = [super init];
    if (self) {
        // Copy common stuff. (TODO: maybe put this in a shared object?)
        _ascender = run->_ascender;
        _descender = run->_descender;
        _lineHeight = run->_lineHeight;
        _arrayBuffer = run->_arrayBuffer;
        _indexBuffer = run->_indexBuffer;
        _textColor = run->_textColor;
        _fontData = run->_fontData;
        _runData = run->_runData;
        _positions = run->_positions;
        _glyphs = run->_glyphs;
        
        // Adjust pointers.
        _start = MIN(start, run->_end);
        _end = MIN(end, run->_end);
        AP_CHECK(_start <= _end, abort());
        AP_CHECK(_start >= run->_start, abort());
        AP_CHECK(_end <= run->_end, abort());
    }
    return self;
}

- (AP_Font_Run*) initWithData:(AP_Font_Data*)data pointSize:(CGFloat)pointSize glyphs:(unsigned char*)glyphs length:(size_t)length
{
    self = [super init];
    if (self) {
        _fontData = data;

        NSMutableData* runData = [NSMutableData dataWithLength:((length + 1) * sizeof(float) + length * sizeof(unsigned char))];
        _runData = runData;
        _start = 0;
        _end = length;
        _positions = (float*) [runData bytes];
        _glyphs = (unsigned char*) (_positions + 1 + length);
        AP_CHECK(_glyphs + length == (unsigned char*)runData.bytes + runData.length, abort());

        // Each character = one quad = four vertices, six indices.
        NSMutableData* vertexData = [NSMutableData dataWithLength:(length * 4 * sizeof(VertexData))];
        NSMutableData* indexData = [NSMutableData dataWithLength:(length * 6 * sizeof(GLushort))];

        VertexData* vPtr = (VertexData*)vertexData.bytes;
        GLushort *iPtr = (GLushort*)indexData.bytes;
        float* posPtr = _positions;
        unsigned char* glyphPtr = _glyphs;

        float fontToScreen = (pointSize / data.header->emSize);
        float xPos = 0;
        for (int i = 0; i < length; ++i) {
            *posPtr++ = xPos;
            *glyphPtr++ = glyphs[i];

            const fontex_glyph_t* g = [data dataForGlyph:glyphs[i]];
            float wTexels = 1 + ceil((g->x1 - g->x0) * data.header->textureScale);
            float hTexels = 1 + ceil((g->y1 - g->y0) * data.header->textureScale);
            float w = (wTexels / data.header->textureScale) * fontToScreen;
            float h = (hTexels / data.header->textureScale) * fontToScreen;
            float wTex = wTexels / data.header->textureSize;
            float hTex = hTexels / data.header->textureSize;
            for (int y = 0; y <= 1; ++y) {
                for (int x = 0; x <= 1; ++x) {
                    vPtr->x = (g->x0 * fontToScreen) + x * w + xPos;
                    vPtr->y = (g->y0 * fontToScreen) + y * h;
                    vPtr->xTex = (g->xTex / (float)data.header->textureSize) + x * wTex;
                    vPtr->yTex = (g->yTex / (float)data.header->textureSize) + y * hTex;
                    ++vPtr;
                }
            }
            xPos += fontToScreen * g->advance;
            if ((i+1) < length) {
                xPos += fontToScreen * [data kerningForGlyph1:glyphs[i] glyph2:glyphs[i+1]];
            }

            GLushort index = i * 4;
            GLushort bottomLeft = index;
            GLushort bottomRight = index + 1;
            GLushort topLeft = index + 2;
            GLushort topRight = index + 3;
            *iPtr++ = bottomRight;
            *iPtr++ = bottomLeft;
            *iPtr++ = topLeft;
            *iPtr++ = topLeft;
            *iPtr++ = topRight;
            *iPtr++ = bottomRight;
        }
        *posPtr++ = xPos;
        AP_CHECK(posPtr == (float*)_glyphs, abort());

        AP_CHECK((const char*)vPtr == (const char*)vertexData.bytes + vertexData.length, abort());
        AP_CHECK((const char*)iPtr == (const char*)indexData.bytes + indexData.length, abort());

        _arrayBuffer = [AP_GLBuffer bufferWithTarget:GL_ARRAY_BUFFER usage:GL_STATIC_DRAW data:vertexData];
        _indexBuffer = [AP_GLBuffer bufferWithTarget:GL_ELEMENT_ARRAY_BUFFER usage:GL_STATIC_DRAW data:indexData];

        _ascender = fontToScreen * data.header->ascent;
        _descender = fontToScreen * data.header->descent;
        _lineHeight = fontToScreen * (data.header->ascent - data.header->descent + data.header->leading);
        _origin = CGPointMake(0, 0);

        _textColor = GLKVector4Make(0, 0, 0, 1);
    }
    return self;
}

- (CGSize) size
{
    return CGSizeMake(_positions[_end] - _positions[_start], _lineHeight);
}

- (size_t) numChars
{
    return _end - _start;
}

- (AP_Font_Run*) splitAtWidth:(CGFloat)width leaving:(AP_Font_Run**)leftover
{
    int lastBreak = _start - 1;
    for (int i = _start; i < _end; ++i) {
        if (_positions[i] - _positions[_start] > width) {
            *leftover = [[AP_Font_Run alloc] initWithRun:self start:(lastBreak + 1) end:_end];
            return [[AP_Font_Run alloc] initWithRun:self start:_start end:MAX(_start, lastBreak)];
        }
        if ([_fontData isWordBreak:_glyphs[i]]) {
            lastBreak = i;
        }
    }
    *leftover = nil;
    return self;
}

- (AP_Font_Run*) splitAtLineBreakLeaving: (AP_Font_Run**)leftover
{
    for (int i = _start; i < _end; ++i) {
        if ([_fontData isLineBreak:_glyphs[i]]) {
            *leftover = [[AP_Font_Run alloc] initWithRun:self start:(i + 1) end:_end];
            return [[AP_Font_Run alloc] initWithRun:self start:_start end:i];
        }
    }
    *leftover = nil;
    return self;
}

- (UIColor*) textColor
{
    return AP_VectorToColor(_textColor);
}

- (void) setTextColor:(UIColor*)color
{
    _textColor = AP_ColorToVector(color);
}

#define MULTILINE(...) #__VA_ARGS__

- (void) renderWithBoundsToGL:(CGAffineTransform)boundsToGL alpha:(CGFloat)alpha
{
    GLKVector4 rgba = _textColor;
    rgba.a *= alpha;
    [self renderWithBoundsToGL:boundsToGL color:rgba];
}

- (void) renderWithBoundsToGL:(CGAffineTransform)boundsToGL color:(GLKVector4)rgba
{
    static const char* kVertex = MULTILINE(
        precision highp float;
        uniform mat3 transform;
        attribute vec2 pos;
        attribute vec2 texCoord;
        varying vec2 _texCoord;
        void main() {
            vec3 tpos = transform * vec3(pos, 1);
            gl_Position = vec4(tpos, 1);
            _texCoord = texCoord;
        }
    );

    static const char* kFragment = MULTILINE(
        precision highp float;
        uniform vec4 color;
        varying vec2 _texCoord;
        uniform sampler2D texture;
        void main() {
            float alpha = texture2D(texture, _texCoord).r;
            gl_FragColor = vec4(color.rgb, color.a * alpha);
        }
    );

    static AP_GLProgram* prog;
    static GLint transform;
    static GLint color;
    static GLint texture;
    static GLint pos;
    static GLint texCoord;

    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        prog = [[AP_GLProgram alloc] initWithVertex:kVertex fragment:kFragment];
        transform = [prog uniform:@"transform"];
        color = [prog uniform:@"color"];
        texture = [prog uniform:@"texture"];
        pos = [prog attr:@"pos"];
        texCoord = [prog attr:@"texCoord"];
    }

    if (_end > _start && rgba.a > 0) {
        boundsToGL = CGAffineTransformTranslate(boundsToGL, _origin.x - _positions[_start], _origin.y);
        GLKMatrix3 matrix = GLKMatrix3Make(
            boundsToGL.a, boundsToGL.b, 0,
            boundsToGL.c, boundsToGL.d, 0,
            boundsToGL.tx, boundsToGL.ty, 1);

        AP_CHECK(prog, return);
        [prog use];

        [_indexBuffer bind];
        [_arrayBuffer bind];
        glEnableVertexAttribArray(pos);
        glEnableVertexAttribArray(texCoord);

        glActiveTexture(GL_TEXTURE0);
        glUniform1i(texture, 0);
        [_fontData.texture bind];

        glUniform4fv(color, 1, rgba.v);
        glUniformMatrix3fv(transform, 1, false, matrix.m);
        glVertexAttribPointer(pos, 2, GL_FLOAT, false, 16, 0);
        glVertexAttribPointer(texCoord, 2, GL_FLOAT, false, 16, (void*)8);

        glDrawElements(GL_TRIANGLES, 6 * (_end - _start), GL_UNSIGNED_SHORT, (void*)(_start * 6 * sizeof(GLushort)));
    }
}

@end
