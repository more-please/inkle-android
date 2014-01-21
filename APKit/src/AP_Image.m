#import "AP_Image.h"

#import <assert.h>
#import <GLKit/GLKit.h>

#import "AP_Bundle.h"
#import "AP_Cache.h"
#import "AP_Check.h"
#import "AP_GLBuffer.h"
#import "AP_GLProgram.h"
#import "AP_GLTexture.h"
#import "AP_Window.h"
#import "NSObject+AP_KeepAlive.h"

@interface AP_Image_Program : AP_GLProgram
@property GLint transform;
@property GLint alpha;
@property GLint pos;
@property GLint texCoord;
@end

@implementation AP_Image_Program

AP_BAN_EVIL_INIT

- (AP_Image_Program*) initWithVertex:(const char*)vertex fragment:(const char*)fragment
{
    self = [super initWithVertex:vertex fragment:fragment];
    if (self) {
        _transform = [self uniform:@"transform"];
        _alpha = [self uniform:@"alpha"];
        _pos = [self attr:@"pos"];
        _texCoord = [self attr:@"texCoord"];
    }
    return self;
}

@end

#define MULTILINE(...) #__VA_ARGS__

static const char* kVertex = MULTILINE(
    precision highp float;
    uniform mat3 transform;
    attribute vec2 pos;
    attribute vec2 texCoord;
    varying vec2 solidTexCoord;
    varying vec2 alphaTexCoord;
    void main() {
        vec3 tpos = transform * vec3(pos, 1);
        gl_Position = vec4(tpos, 1);
        solidTexCoord = texCoord;
        alphaTexCoord = vec2(1.0 - texCoord.x, texCoord.y);
    }
);

static const char* kAlphaFragment = MULTILINE(
    precision highp float;
    uniform float alpha;
    varying vec2 solidTexCoord;
    varying vec2 alphaTexCoord;
    uniform sampler2D texture;
    void main() {
        vec4 pixel = texture2D(texture, solidTexCoord, -1.0);
        vec4 pixelAlpha = texture2D(texture, alphaTexCoord);
        gl_FragColor = vec4(pixel.rgb, pixelAlpha.g * alpha);
    }
);

static const char* kSolidFragment = MULTILINE(
    precision highp float;
    uniform float alpha;
    varying vec2 solidTexCoord;
    uniform sampler2D texture;
    void main() {
        vec4 pixel = texture2D(texture, solidTexCoord, -1.0);
        pixel.a *= alpha;
        gl_FragColor = pixel;
    }
);

static AP_Image_Program* g_SolidProg;
static AP_Image_Program* g_AlphaProg;

@implementation AP_Image {
    AP_GLBuffer* _arrayBuffer;
    AP_GLBuffer* _indexBuffer;
    AP_GLTexture* _texture;
    int _numAlpha;
    int _numSolid;
    CGSize _size;
}

+ (AP_Image*) imageNamed:(NSString *)name
{
    AP_CHECK(name, return nil);
    NSString* img;
    if ([name hasSuffix:@".png.img"]) {
        img = name;
    } else if ([name hasSuffix:@".png"]) {
        img = [name stringByAppendingString:@".img"];
    } else {
        img = [name stringByAppendingString:@".png.img"];
    }

    NSString* png = [img stringByDeletingPathExtension];
    AP_CHECK([png hasSuffix:@".png"], return (AP_Image*)nil);

    static AP_Cache* g_ImageCache;
    if (!g_ImageCache) {
        g_ImageCache = [[AP_Cache alloc] init];
    }
    AP_CHECK(g_ImageCache, return nil);

    AP_Image* result = [g_ImageCache get:img withLoader:^{
        NSData* data = [AP_Bundle dataForResource:img ofType:nil];
        if (data) {
            return [[AP_Image alloc] initWithName:img data:data];
        }

        AP_GLTexture* texture = [AP_GLTexture textureNamed:png];
        if (texture) {
            return [[AP_Image alloc] initWithName:img texture:texture];
        }

        NSLog(@"Failed to load image: %@", png);
        return (AP_Image*)nil;
    }];

    return result;
}

static float sqrtSize(CGSize size) {
    return sqrt(size.width * size.height);
}

+ (AP_Image*) imageWithContentsOfFileNamedAuto:(NSString*)name
{
    AP_Image* result = [AP_Image imageNamed:name];
    if (result) {
        // This is typically a 4x image for retina iPads (2048x1536 screen).
        // Adjust the scale proportionately to the size of the screen.
        result->_scale = [AP_Window iPhone:4.0 iPad:2.0];
    }
    return result;
}

- (CGSize) size
{
    return CGSizeMake(_size.width / _scale, _size.height / _scale);
}

- (CGSize) pixelSize
{
    return _size;
}

typedef struct Header {
    int16_t width;
    int16_t height;
    int16_t numAlpha;
    int16_t numSolid;
} Header;

typedef struct Quad {
    int16_t x, y;
    int16_t xTex, yTex;
    int16_t width, height;
} Quad;

typedef struct VertexData {
    GLfloat x, y;
    GLfloat xTex, yTex;
} VertexData;

AP_BAN_EVIL_INIT

- (void) commonInit
{
    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        g_SolidProg = [[AP_Image_Program alloc] initWithVertex:kVertex fragment:kSolidFragment];
        g_AlphaProg = [[AP_Image_Program alloc] initWithVertex:kVertex fragment:kAlphaFragment];
    }
    AP_CHECK(g_SolidProg, abort());
    AP_CHECK(g_AlphaProg, abort());
}

- (AP_Image*) initWithName:(NSString*)name texture:(AP_GLTexture*)texture
{
    AP_CHECK(name, return nil);
    AP_CHECK(texture, return nil);

    self = [super init];
    if (self) {
        [self commonInit];
        _assetName = name;
        _texture = texture;
        _size = CGSizeMake(_texture.width, _texture.height);
        _scale = 1;
        _numAlpha = 0;
        _numSolid = 1;

        // For each quad, we need 4 vertices (16 bytes each) and 6 indices (2 bytes each).
        NSMutableData* vertexData = [NSMutableData dataWithLength:(4 * 16)];
        NSMutableData* indexData = [NSMutableData dataWithLength:(6 * 2)];
        VertexData* vPtr = (VertexData*) vertexData.bytes;
        GLushort* iPtr = (GLushort*) indexData.bytes;

        for (int x = 0; x <= 1; ++x) {
            for (int y = 0; y <= 1; ++y) {
                vPtr->x = (x - 0.5) * _size.width;
                vPtr->y = (y - 0.5) * _size.height;
                vPtr->xTex = x;
                vPtr->yTex = y;
                ++vPtr;
            }
        }

        GLushort index = 0;
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

        _arrayBuffer = [AP_GLBuffer bufferWithTarget:GL_ARRAY_BUFFER usage:GL_STATIC_DRAW data:vertexData];
        _indexBuffer = [AP_GLBuffer bufferWithTarget:GL_ELEMENT_ARRAY_BUFFER usage:GL_STATIC_DRAW data:indexData];
    }
    NSLog(@"Loaded image: %@", name);
    return self;
}

- (AP_Image*) initWithName:(NSString*)name data:(NSData*)data {
    AP_CHECK(name, return nil);
    AP_CHECK(data, return nil);

    AP_CHECK_EQ(sizeof(Header), 8, return nil);
    AP_CHECK_EQ(sizeof(Quad), 12, return nil);

    self = [super init];
    if (self) {
        [self commonInit];
        _assetName = name;

        const uint8_t* bytes = data.bytes;
        const Header* header = (const Header*) &bytes[0];
        const Quad* quads = (const Quad*) (header + 1);

        AP_CHECK_GE(data.length, sizeof(Header), return nil);

        _size = CGSizeMake(header->width, header->height);
        _scale = 1;
        _numAlpha = header->numAlpha;
        _numSolid = header->numSolid;

        int numQuads = _numAlpha + _numSolid;

        int texNameStart = sizeof(Header) + numQuads * sizeof(Quad);
        int texNameLength = data.length - texNameStart - 1;
        const uint8_t* texNamePtr = &bytes[texNameStart];

        AP_CHECK_GE(texNameLength, 0, return nil);

        NSString* texName = [[NSString alloc] initWithBytes:texNamePtr length:texNameLength encoding:NSUTF8StringEncoding];
        _texture = [AP_GLTexture textureNamed:texName];

        AP_CHECK(_texture, return nil);

        [_texture bind];

        GLfloat texWidth = _texture.width;
        GLfloat texHeight = _texture.height;

        AP_CHECK_GE(texWidth, 0, return nil);
        AP_CHECK_GE(texHeight, 0, return nil);

        // For each quad, we need 4 vertices (16 bytes each) and 6 indices (2 bytes each).
        NSMutableData* vertexData = [NSMutableData dataWithLength:(4 * numQuads * 16)];
        NSMutableData* indexData = [NSMutableData dataWithLength:(6 * numQuads * 2)];
        VertexData* vPtr = (VertexData*) vertexData.bytes;
        GLushort* iPtr = (GLushort*) indexData.bytes;

        for (int i = 0; i < numQuads; ++i) {
            const Quad* quad = quads + i;
            for (float y = 0; y <= quad->height; y += quad->height) {
                for (float x = 0; x <= quad->width; x += quad->width) {
                    vPtr->x = x + quad->x - _size.width/2;
                    vPtr->y = y + quad->y - _size.height/2;
                    vPtr->xTex = (x + quad->xTex) / texWidth;
                    vPtr->yTex = (y + quad->yTex) / texHeight;
                    ++vPtr;
                }
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

        _arrayBuffer = [AP_GLBuffer bufferWithTarget:GL_ARRAY_BUFFER usage:GL_STATIC_DRAW data:vertexData];
        _indexBuffer = [AP_GLBuffer bufferWithTarget:GL_ELEMENT_ARRAY_BUFFER usage:GL_STATIC_DRAW data:indexData];
    }
    NSLog(@"Loaded image: %@", name);
    return self;
}

- (void) dealloc
{
    NSLog(@"Deleted image: %@", _assetName);
    if (_texture) {
        [_texture keepAliveForTimeInterval:3.0];
    }
}

- (void) renderGLWithTransform:(CGAffineTransform)transform alpha:(CGFloat)alpha
{
    if (alpha <= 0) {
        return;
    }

    GLKMatrix3 matrix = GLKMatrix3Make(
        transform.a, transform.b, 0,
        transform.c, transform.d, 0,
        transform.tx, transform.ty, 1);

    glDisable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glBindTexture(GL_TEXTURE_2D, _texture.name);

    [g_AlphaProg use];
    [_arrayBuffer bind];
    [_indexBuffer bind];

    glUniform1f(g_AlphaProg.alpha, alpha);
    glUniformMatrix3fv(g_AlphaProg.transform, 1, false, matrix.m);

    glEnableVertexAttribArray(g_AlphaProg.pos);
    glEnableVertexAttribArray(g_AlphaProg.texCoord);
    glVertexAttribPointer(g_AlphaProg.pos, 2, GL_FLOAT, false, 16, 0);
    glVertexAttribPointer(g_AlphaProg.texCoord, 2, GL_FLOAT, false, 16, (void*)8);

    glDrawElements(GL_TRIANGLES, 6 * _numAlpha, GL_UNSIGNED_SHORT, 0);

    [g_SolidProg use];
    [_arrayBuffer bind];
    [_indexBuffer bind];

    glUniform1f(g_SolidProg.alpha, alpha);
    glUniformMatrix3fv(g_SolidProg.transform, 1, false, matrix.m);

    glEnableVertexAttribArray(g_SolidProg.pos);
    glEnableVertexAttribArray(g_SolidProg.texCoord);
    glVertexAttribPointer(g_SolidProg.pos, 2, GL_FLOAT, false, 16, 0);
    glVertexAttribPointer(g_SolidProg.texCoord, 2, GL_FLOAT, false, 16, (void*)8);

    glDrawElements(GL_TRIANGLES, 6 * _numSolid, GL_UNSIGNED_SHORT, (void*)(12 * _numAlpha));
}

- (AP_Image*) resizableImageWithCapInsets:(UIEdgeInsets)capInsets
{
    AP_NOT_IMPLEMENTED;
    return self;
}

- (AP_Image*) stretchableImageWithLeftCapWidth:(NSInteger)leftCapWidth topCapHeight:(NSInteger)topCapHeight
{
    AP_NOT_IMPLEMENTED;
    return self;
}

- (AP_Image*) tintedImageUsingColor:(UIColor*)tintColor
{
    AP_NOT_IMPLEMENTED;
    return self;
}

@end
