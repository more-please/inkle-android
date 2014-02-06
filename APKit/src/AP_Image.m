#import "AP_Image.h"

#import <assert.h>
#import <GLKit/GLKit.h>

#import "AP_Bundle.h"
#import "AP_Cache.h"
#import "AP_Check.h"
#import "AP_GLBuffer.h"
#import "AP_GLProgram.h"
#import "AP_GLTexture.h"
#import "AP_Utils.h"
#import "AP_Window.h"
#import "NSObject+AP_KeepAlive.h"

@interface AP_Image_Program : AP_GLProgram
@property GLint transform;
@property GLint stretch;
@property GLint alpha;
@property GLint tint;
@property GLint edgePos;
@property GLint stretchPos;
@property GLint texCoord;
@end

@implementation AP_Image_Program

AP_BAN_EVIL_INIT

- (AP_Image_Program*) initWithVertex:(const char*)vertex fragment:(const char*)fragment
{
    self = [super initWithVertex:vertex fragment:fragment];
    if (self) {
        _transform = [self uniform:@"transform"];
        _stretch = [self uniform:@"stretch"];
        _alpha = [self uniform:@"alpha"];
        _tint = [self uniform:@"tint"];
        _edgePos = [self attr:@"edgePos"];
        _stretchPos = [self attr:@"stretchPos"];
        _texCoord = [self attr:@"texCoord"];
    }
    return self;
}

@end

#define MULTILINE(...) #__VA_ARGS__

static const char* kVertex = MULTILINE(
    precision highp float;
    uniform mat3 transform;
    uniform vec2 stretch;
    attribute vec2 edgePos;
    attribute vec2 stretchPos;
    attribute vec2 texCoord;
    varying vec2 solidTexCoord;
    varying vec2 alphaTexCoord;
    void main() {
        vec2 pos = edgePos + stretch * stretchPos;
        vec3 tpos = transform * vec3(pos, 1);
        gl_Position = vec4(tpos, 1);
        solidTexCoord = texCoord;
        alphaTexCoord = vec2(1.0 - texCoord.x, texCoord.y);
    }
);

static const char* kAlphaFragment = MULTILINE(
    precision highp float;
    uniform float alpha;
    uniform vec4 tint;
    varying vec2 solidTexCoord;
    varying vec2 alphaTexCoord;
    uniform sampler2D texture;
    void main() {
        vec4 pixel = texture2D(texture, solidTexCoord, -1.0);
        vec3 tinted = mix(pixel.rgb, tint.rgb, tint.a);
        float pixelAlpha = texture2D(texture, alphaTexCoord).g;
        gl_FragColor = vec4(tinted.rgb, pixelAlpha * alpha);
    }
);

static const char* kSolidFragment = MULTILINE(
    precision highp float;
    uniform float alpha;
    uniform vec4 tint;
    varying vec2 solidTexCoord;
    uniform sampler2D texture;
    void main() {
        vec4 pixel = texture2D(texture, solidTexCoord, -1.0);
        vec3 tinted = mix(pixel.rgb, tint.rgb, tint.a);
        gl_FragColor = vec4(tinted.rgb, pixel.a * alpha);
    }
);

static AP_Image_Program* g_SolidProg;
static AP_Image_Program* g_AlphaProg;

typedef struct Header {
    int16_t width;
    int16_t height;
    int16_t numAlpha;
    int16_t numSolid;
} Header;

typedef struct RawQuad {
    int16_t x, y;
    int16_t xTex, yTex;
    int16_t width, height;
} RawQuad;

typedef struct StretchyQuad {
    CGRect edge;
    CGRect stretch;
    CGRect tex;
} StretchyQuad;

typedef struct VertexData {
    GLfloat xEdge, yEdge;
    GLfloat xStretch, yStretch;
    GLfloat xTex, yTex;
} VertexData;

@implementation AP_Image {
    AP_GLTexture* _texture;
    CGSize _size;
    NSMutableData* _solidQuads;
    NSMutableData* _alphaQuads;
    GLKVector4 _tint;

    // These are constructed lazily at render time.
    AP_GLBuffer* _arrayBuffer;
    AP_GLBuffer* _indexBuffer;
    int _numSolid;
    int _numAlpha;
    int _xTile; // Number of times to tile the center section horizontally
    int _yTile; // Number of times to tile the center section vertically
}

+ (AP_Image*) imageNamed:(NSString *)name
{
    AP_Image* result = [AP_Image imageNamed:name scale:1];
    return result;
}

+ (AP_Image*) imageWithContentsOfFileNamedAuto:(NSString*)name
{
    // This is typically a 4x image for retina iPads (2048x1536 screen).
    // Adjust the scale proportionately to the size of the screen.
    // GL has been set up as if for a non-retina screen, so we include
    // a 2x factor for that.
    CGFloat scale = [AP_Window scaleForIPhone:4.0 iPad:2.0];
    AP_Image* result = [AP_Image imageNamed:name scale:scale];
    return result;
}

+ (AP_Image*) imageWithContentsOfFileNamed2x:(NSString*)name
{
    // This is a 2x image for retina iPhones or iPads.
    AP_Image* result = [AP_Image imageNamed:name scale:2];
    return result;
}

+ (AP_Image*) imageNamed:(NSString*)name scale:(CGFloat)scale
{
    AP_CHECK(name, return nil);
    NSString* img;
    if ([name hasSuffix:@".png.img"]) {
        img = name;
    } else if ([name hasSuffix:@".png"] || [name hasSuffix:@".jpg"]) {
        img = [name stringByAppendingString:@".img"];
    } else {
        img = [name stringByAppendingString:@".png.img"];
    }

    NSString* tex = [img stringByDeletingPathExtension];

    static AP_Cache* g_ImageCache;
    if (!g_ImageCache) {
        // Images are relatively small, so use a big cache.
        // The actual backing textures are cached separately.
        g_ImageCache = [[AP_Cache alloc] initWithSize:50];
    }
    AP_CHECK(g_ImageCache, return nil);

    AP_Image* result = [g_ImageCache get:img withLoader:^{
        NSData* data = [AP_Bundle dataForResource:img ofType:nil];
        if (data) {
            return [[AP_Image alloc] initWithName:img data:data scale:scale];
        }

        AP_GLTexture* texture = [AP_GLTexture textureNamed:tex];
        if (texture) {
            return [[AP_Image alloc] initWithName:img texture:texture scale:scale];
        }

        NSLog(@"Failed to load image: %@", tex);
        return (AP_Image*)nil;
    }];

    AP_CHECK([result isKindOfClass:[AP_Image class]], abort());

    if (result.scale != scale) {
        // This can happen if the image was cached before the screen was rotated.
        result = [[AP_Image alloc] initWithImage:result];
        result->_scale = scale;
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

AP_BAN_EVIL_INIT

- (AP_Image*) initWithImage:(AP_Image*)other
{
    AP_CHECK(other, return nil);
    self = [super init];
    if (self) {
        _assetName = other->_assetName;
        _insets = other->_insets;
        _scale = other->_scale;

        _texture = other->_texture;
        _size = other->_size;
        _solidQuads = other->_solidQuads;
        _alphaQuads = other->_alphaQuads;
        _tint = other->_tint;

        _arrayBuffer = other->_arrayBuffer;
        _indexBuffer = other->_indexBuffer;
        _numSolid = other->_numSolid;
        _numAlpha = other->_numAlpha;
        _xTile = other->_xTile;
        _yTile = other->_yTile;

        _resizingMode = other->_resizingMode;
    }
    return self;
}

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

    _insets = UIEdgeInsetsZero;

    _solidQuads = [NSMutableData data];
    _alphaQuads = [NSMutableData data];

    _arrayBuffer = nil;
    _indexBuffer = nil;

    _xTile = _yTile = 1;

    _resizingMode = UIImageResizingModeTile;
}

- (void) addRaw:(RawQuad)raw solid:(BOOL)solid
{
    CGRect r = {
        raw.x,
        raw.y,
        raw.width,
        raw.height
    };
    CGPoint texPos = {
        raw.xTex / (CGFloat)_texture.width,
        raw.yTex / (CGFloat)_texture.height,
    };
    [self addRect:r texPos:texPos solid:solid];
}

- (void) addStretchy:(StretchyQuad)quad solid:(BOOL)solid
{
    CGRect r = {
        quad.edge.origin.x + quad.stretch.origin.x,
        quad.edge.origin.y + quad.stretch.origin.y,
        quad.edge.size.width + quad.stretch.size.width,
        quad.edge.size.height + quad.stretch.size.height,
    };
    CGPoint texPos = quad.tex.origin;
    [self addRect:r texPos:texPos solid:solid];
}

- (void) addRect:(CGRect)r texPos:(CGPoint)texPos solid:(BOOL)solid
{
    // Depending on the edge insets, we may have to split
    // up each input quad into as many as nine pieces.
    // All coordinates come in two parts, "edge" (constant)
    // and "stretch" (variable depending on the view bounds).

    // Calculate the total amount of edge space and stretch space.
    UIEdgeInsets edge = {
        _insets.top * _scale,
        _insets.left * _scale,
        _insets.bottom * _scale,
        _insets.right * _scale,
    };
    CGSize stretch = {
        _size.width - (edge.left + edge.right),
        _size.height - (edge.top + edge.bottom),
    };

    // Calculate the edge/stretch positions at the boundaries between the nine patches.
    const CGPoint edgePos[4] = {
        { 0, 0 },
        { edge.left, edge.top },
        { edge.left, edge.top },
        { edge.left + edge.right, edge.top + edge.bottom },
    };
    const CGPoint stretchPos[4] = {
        { 0, 0 },
        { 0, 0 },
        { stretch.width, stretch.height },
        { stretch.width, stretch.height },
    };

    AP_CHECK(_texture, return);
    float texWidth = _texture.width;
    float texHeight = _texture.height;

    StretchyQuad q;
    for (int i = 0; i < 3; i++) {
        float left = MAX(edgePos[i].x + stretchPos[i].x, r.origin.x);
        float right = MIN(edgePos[i+1].x + stretchPos[i+1].x, r.origin.x + r.size.width);
        if (left >= right) {
            continue;
        }

        q.edge.origin.x = edgePos[i].x;
        q.stretch.origin.x = stretchPos[i].x;
        q.edge.size.width = 0;
        q.stretch.size.width = 0;
        if (i == 1) {
            q.stretch.origin.x += left - (q.edge.origin.x + q.stretch.origin.x);
            q.stretch.size.width = right - left;
        } else {
            q.edge.origin.x += left - (q.edge.origin.x + q.stretch.origin.x);
            q.edge.size.width = right - left;
        }

        for (int j = 0; j < 3; j++) {
            float top = MAX(edgePos[j].y + stretchPos[j].y, r.origin.y);
            float bottom = MIN(edgePos[j+1].y + stretchPos[j+1].y, r.origin.y + r.size.height);
            if (top >= bottom) {
                continue;
            }

            q.edge.origin.y = edgePos[j].y;
            q.stretch.origin.y = stretchPos[j].y;
            q.edge.size.height = 0;
            q.stretch.size.height = 0;
            if (j == 1) {
                q.stretch.origin.y += top - (q.edge.origin.y + q.stretch.origin.y);
                q.stretch.size.height = bottom - top;
            } else {
                q.edge.origin.y += top - (q.edge.origin.y + q.stretch.origin.y);
                q.edge.size.height = bottom - top;
            }

            q.tex.origin.x = texPos.x + (q.edge.origin.x + q.stretch.origin.x - r.origin.x) / texWidth;
            q.tex.origin.y = texPos.y + (q.edge.origin.y + q.stretch.origin.y - r.origin.y) / texHeight;
            q.tex.size.width = (q.edge.size.width + q.stretch.size.width) / texWidth;
            q.tex.size.height = (q.edge.size.height + q.stretch.size.height) / texHeight;

            if (solid) {
                [_solidQuads appendBytes:&q length:sizeof(StretchyQuad)];
            } else {
                [_alphaQuads appendBytes:&q length:sizeof(StretchyQuad)];
            }
        }
    }
}

- (AP_Image*) stretchableImageWithLeftCapWidth:(NSInteger)leftCapWidth topCapHeight:(NSInteger)topCapHeight
{
    UIEdgeInsets insets;
    insets.left = leftCapWidth;
    insets.right = (_size.width / _scale) - leftCapWidth - 1;
    insets.top = topCapHeight;
    insets.bottom = (_size.height / _scale) - topCapHeight - 1;
    AP_Image* result = [self resizableImageWithCapInsets:insets];
    result->_resizingMode = UIImageResizingModeStretch;
    return result;
}

- (AP_Image*) resizableImageWithCapInsets:(UIEdgeInsets)capInsets
{
    return [[AP_Image alloc] initWithImage:self insets:capInsets];
}

- (AP_Image*) initWithImage:(AP_Image*)other insets:(UIEdgeInsets)insets
{
    self = [super init];
    if (self) {
        [self commonInit];

        _assetName = other->_assetName;
        _texture = other->_texture;
        _size = other->_size;
        _scale = other->_scale;

        // Make sure there's at least a 1-pixel space in the middle.
        if (insets.left + insets.right + 1 > (_size.width / _scale)) {
            CGFloat scale = (insets.left + insets.right + 1) / (_size.width / _scale);
            insets.left /= scale;
            insets.right /= scale;
        }
        if (insets.top + insets.bottom + 1 > _size.height) {
            CGFloat scale = (insets.top + insets.bottom + 1) / (_size.height / _scale);
            insets.top /= scale;
            insets.bottom /= scale;
        }

        _insets = insets;

        int numAlpha = other->_alphaQuads.length / sizeof(StretchyQuad);
        const StretchyQuad* alphaQuads = (const StretchyQuad*) other->_alphaQuads.bytes;
        for (int i = 0; i < numAlpha; i++) {
            [self addStretchy:alphaQuads[i] solid:NO];
        }

        int numSolid = other->_solidQuads.length / sizeof(StretchyQuad);
        const StretchyQuad* solidQuads = (const StretchyQuad*) other->_solidQuads.bytes;
        for (int i = 0; i < numSolid; i++) {
            [self addStretchy:solidQuads[i] solid:YES];
        }

        // Speculative: is "other" being collected by ARC?
        [other self];
    }
    NSLog(@"Added insets to image: %@", _assetName);
    return self;
}

- (AP_Image*) initWithName:(NSString*)name texture:(AP_GLTexture*)texture scale:(CGFloat)scale
{
    AP_CHECK(name, return nil);
    AP_CHECK(texture, return nil);

    self = [super init];
    if (self) {
        [self commonInit];
        _assetName = name;
        _texture = texture;
        _size = CGSizeMake(_texture.width, _texture.height);
        _scale = scale;

        RawQuad q;
        q.x = 0;
        q.y = 0;
        q.xTex = 0;
        q.yTex = 0;
        q.width = _texture.width;
        q.height = _texture.height;

        [self addRaw:q solid:YES];
    }
    NSLog(@"Loaded image: %@", name);
    return self;
}

- (AP_Image*) initWithName:(NSString*)name data:(NSData*)data scale:(CGFloat)scale {
    AP_CHECK(name, return nil);
    AP_CHECK(data, return nil);

    AP_CHECK_EQ(sizeof(Header), 8, return nil);
    AP_CHECK_EQ(sizeof(RawQuad), 12, return nil);

    self = [super init];
    if (self) {
        [self commonInit];
        _assetName = name;
        _scale = scale;

        // Load header
        const uint8_t* bytes = data.bytes;
        const Header* header = (const Header*) &bytes[0];
        const RawQuad* quads = (const RawQuad*) (header + 1);
        AP_CHECK_GE(data.length, sizeof(Header), return nil);

        // Load metrics
        int numQuads = header->numAlpha + header->numSolid;
        _size = CGSizeMake(header->width, header->height);

        // Load texture name
        int texNameStart = sizeof(Header) + numQuads * sizeof(RawQuad);
        int texNameLength = data.length - texNameStart - 1;
        AP_CHECK_GE(texNameLength, 0, return nil);

        // Load texture
        const uint8_t* texNamePtr = &bytes[texNameStart];
        NSString* texName = [[NSString alloc] initWithBytes:texNamePtr length:texNameLength encoding:NSUTF8StringEncoding];
        _texture = [AP_GLTexture textureNamed:texName];
        AP_CHECK(_texture, return nil);

        // Load quads
        for (int i = 0; i < header->numAlpha; i++) {
            [self addRaw:quads[i] solid:NO];
        }
        for (int i = header->numAlpha; i < numQuads; i++) {
            [self addRaw:quads[i] solid:YES];
        }
    }
    NSLog(@"Loaded image: %@", name);
    return self;
}

- (void) dealloc
{
    NSLog(@"Deleted image: %@", _assetName);
}

static int xTilesInQuad(const StretchyQuad* q, int xTile) {
    return (q->stretch.size.width > 0) ? xTile : 1;
}

static int yTilesInQuad(const StretchyQuad* q, int yTile) {
    return (q->stretch.size.height > 0) ? yTile : 1;
}

static int countTilesInQuad(const StretchyQuad* q, int xTile, int yTile) {
    return xTilesInQuad(q, xTile) * yTilesInQuad(q, yTile);
}

static int countTilesInQuads(NSData* data, int xTile, int yTile) {
    const StretchyQuad* q = (const StretchyQuad*)data.bytes;
    size_t count = data.length / sizeof(StretchyQuad);
    int result = 0;
    for (int i = 0; i < count; i++) {
        result += countTilesInQuad(q+i, xTile, yTile);
    }
    return result;
}

- (void) renderGLWithSize:(CGSize)size transform:(CGAffineTransform)transform alpha:(CGFloat)alpha
{
    if (alpha <= 0) {
        return;
    }

    CGSize edgeSize = {
        (_insets.left + _insets.right) * _scale,
        (_insets.top + _insets.bottom) * _scale,
    };

    // Calculate how many times we need to tile the centre section.
    CGSize naturalSize = {
        _size.width - edgeSize.width,
        _size.height - edgeSize.height,
    };
    CGSize displaySize = {
        size.width * _scale - edgeSize.width,
        size.height * _scale - edgeSize.height,
    };

    int xTile = 1;
    int yTile = 1;
    if (edgeSize.width > 0 || edgeSize.height > 0) {
        xTile = (displaySize.width > 0) ? floorf(0.3 + displaySize.width / naturalSize.width) : 0;
        yTile = (displaySize.height > 0) ? floorf(0.3 + displaySize.height / naturalSize.height) : 0;
    }
    if (_resizingMode == UIImageResizingModeStretch) {
        xTile = MIN(1, xTile);
        yTile = MIN(1, yTile);
    }

    if (xTile != _xTile || yTile != _yTile) {
        NSLog(@"Tiling changed for image %@ - was %dx%d, now %dx%d (scale: %.3f)", _assetName, _xTile, _yTile, xTile, yTile, _scale);
        // TODO - this changes a lot for story chunks. It would be good to cache
        // the GL data for each tile layout rather than just resetting it.
        _xTile = xTile;
        _yTile = yTile;
        _indexBuffer = 0;
        _arrayBuffer = 0;
    }

    CGSize edgeScale = {
        (xTile > 0) ? 1 : (_scale * size.width / edgeSize.width),
        (yTile > 0) ? 1 : (_scale * size.height / edgeSize.height)
    };
    CGSize stretchSize = {
        (_size.width - edgeSize.width) * xTile,
        (_size.height - edgeSize.height) * yTile,
    };
    CGSize stretchScale = {
        (xTile > 0) ? (displaySize.width / stretchSize.width) : 0,
        (yTile > 0) ? (displaySize.height / stretchSize.height) : 0,
    };

    if (!_indexBuffer || !_arrayBuffer) {
        // Calculate how many quads we have. This depends on the tiling.
        _numSolid = countTilesInQuads(_solidQuads, _xTile, _yTile);
        _numAlpha = countTilesInQuads(_alphaQuads, _xTile, _yTile);
        int numQuads = _numSolid + _numAlpha;

        NSMutableData* data = [_alphaQuads mutableCopy];
        [data appendData:_solidQuads];
        const StretchyQuad* quads = (const StretchyQuad*)(data.bytes);
        const StretchyQuad* maxQuad = quads + data.length / sizeof(StretchyQuad);

        // Upload the quads as GL triangles.
        // For each quad, we need 4 vertices (24 bytes each) and 6 indices (2 bytes each).
        NSMutableData* vertexData = [NSMutableData dataWithLength:(4 * numQuads * 24)];
        NSMutableData* indexData = [NSMutableData dataWithLength:(6 * numQuads * 2)];
        VertexData* vPtr = (VertexData*) vertexData.bytes;
        GLushort* iPtr = (GLushort*) indexData.bytes;

        int count = 0;
        for (const StretchyQuad* q = quads; q < maxQuad; ++q) {
            // Maybe tile the quad
            int hMax = xTilesInQuad(q, _xTile);
            int vMax = yTilesInQuad(q, _yTile);
            for (int h = 0; h < hMax; ++h) {
                for (int v = 0; v < vMax; ++v) {
                    // Okay, we finally have a single quad for GL!
                    CGFloat hOrigin = h * stretchSize.width / hMax;
                    CGFloat vOrigin = v * stretchSize.height / vMax;

                    // Need to hack the "stretch" coordinates if we're on the bottom or right edge, ugh
                    if (_xTile > 0 && q->stretch.origin.x > 0 && q->stretch.size.width == 0) {
                        hOrigin = (_xTile - 1) * stretchSize.width / _xTile;
                    }
                    if (_yTile > 0 && q->stretch.origin.y > 0 && q->stretch.size.height == 0) {
                        vOrigin = (_yTile - 1) * stretchSize.height / _yTile;
                    }

                    // Generate four vertices for the corners.
                    for (int y = 0; y <= 1; y++) {
                        for (int x = 0; x <= 1; x++) {
                            vPtr->xEdge = q->edge.origin.x + x * q->edge.size.width;
                            vPtr->yEdge = q->edge.origin.y + y * q->edge.size.height;
                            vPtr->xStretch = hOrigin + q->stretch.origin.x + x * q->stretch.size.width;
                            vPtr->yStretch = vOrigin + q->stretch.origin.y + y * q->stretch.size.height;
                            vPtr->xTex = q->tex.origin.x + x * q->tex.size.width;
                            vPtr->yTex = q->tex.origin.y + y * q->tex.size.height;
                            ++vPtr;
                        }
                    }

                    // Generate six indices, describing two triangles.
                    GLushort index = (count++) * 4;
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
            }
        }

        // If my calculations are correct, we should just reach the end of each buffer.
        AP_CHECK(count == numQuads, abort());
        AP_CHECK((const char*)vPtr == (const char*)vertexData.bytes + vertexData.length, abort());
        AP_CHECK((const char*)iPtr == (const char*)indexData.bytes + indexData.length, abort());

        // Pass the data to GL! Woohoo, we're done.
        _arrayBuffer = [AP_GLBuffer bufferWithTarget:GL_ARRAY_BUFFER usage:GL_STATIC_DRAW data:vertexData];
        _indexBuffer = [AP_GLBuffer bufferWithTarget:GL_ELEMENT_ARRAY_BUFFER usage:GL_STATIC_DRAW data:indexData];

        // Speculative: is "data" being collected by ARC?
        [data self];
    }

    transform = CGAffineTransformScale(transform, edgeScale.width / _scale, edgeScale.height / _scale);

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
    glUniform2f(g_AlphaProg.stretch, stretchScale.width, stretchScale.height);
    glUniform4fv(g_AlphaProg.tint, 1, _tint.v);

    glEnableVertexAttribArray(g_AlphaProg.edgePos);
    glEnableVertexAttribArray(g_AlphaProg.stretchPos);
    glEnableVertexAttribArray(g_AlphaProg.texCoord);
    glVertexAttribPointer(g_AlphaProg.edgePos, 2, GL_FLOAT, false, 24, 0);
    glVertexAttribPointer(g_AlphaProg.stretchPos, 2, GL_FLOAT, false, 24, (void*)8);
    glVertexAttribPointer(g_AlphaProg.texCoord, 2, GL_FLOAT, false, 24, (void*)16);

    glDrawElements(GL_TRIANGLES, 6 * _numAlpha, GL_UNSIGNED_SHORT, 0);

    [g_SolidProg use];
    [_arrayBuffer bind];
    [_indexBuffer bind];

    glUniform1f(g_SolidProg.alpha, alpha);
    glUniformMatrix3fv(g_SolidProg.transform, 1, false, matrix.m);
    glUniform2f(g_SolidProg.stretch, stretchScale.width, stretchScale.height);
    glUniform4fv(g_SolidProg.tint, 1, _tint.v);

    glEnableVertexAttribArray(g_SolidProg.edgePos);
    glEnableVertexAttribArray(g_SolidProg.stretchPos);
    glEnableVertexAttribArray(g_SolidProg.texCoord);
    glVertexAttribPointer(g_SolidProg.edgePos, 2, GL_FLOAT, false, 24, 0);
    glVertexAttribPointer(g_SolidProg.stretchPos, 2, GL_FLOAT, false, 24, (void*)8);
    glVertexAttribPointer(g_SolidProg.texCoord, 2, GL_FLOAT, false, 24, (void*)16);

    glDrawElements(GL_TRIANGLES, 6 * _numSolid, GL_UNSIGNED_SHORT, (void*)(12 * _numAlpha));
}

- (AP_Image*) tintedImageUsingColor:(UIColor*)tintColor
{
    AP_Image* result = [[AP_Image alloc] initWithImage:self];
    result->_tint = AP_ColorToVector(tintColor);
    return result;
}

@end
