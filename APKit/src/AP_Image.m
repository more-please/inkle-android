#import "AP_Image.h"

#import <assert.h>
#import <GLKit/GLKit.h>

#import "AP_Bundle.h"
#import "AP_Check.h"
#import "AP_GLBuffer.h"
#import "AP_GLProgram.h"
#import "AP_GLTexture.h"
#import "AP_StrongCache.h"
#import "AP_Utils.h"
#import "AP_WeakCache.h"
#import "AP_Window.h"
#import "NSObject+AP_KeepAlive.h"

@interface AP_Image_Program : AP_GLProgram
@property (nonatomic) GLint transform;
@property (nonatomic) GLint stretch;
@property (nonatomic) GLint alpha;
@property (nonatomic) GLint tint;
@property (nonatomic) GLint texture;
@property (nonatomic) GLint alphaTexture;
@property (nonatomic) GLint edgePos;
@property (nonatomic) GLint stretchPos;
@property (nonatomic) GLint texCoord;
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
        _texture = [self uniform:@"texture"];
        _alphaTexture = -1; // Lazy initialize
        _edgePos = [self attr:@"edgePos"];
        _stretchPos = [self attr:@"stretchPos"];
        _texCoord = [self attr:@"texCoord"];
    }
    return self;
}

- (GLint) alphaTexture
{
    if (_alphaTexture < 0) {
        _alphaTexture = [self uniform:@"alphaTexture"];
    }
    return _alphaTexture;
}

@end

static const char* kVertex = AP_SHADER(
    uniform mat3 transform;
    uniform vec2 stretch;
    attribute vec2 edgePos;
    attribute vec2 stretchPos;
    attribute vec2 texCoord;
    varying vec2 f_texCoord;
    void main() {
        vec2 pos = edgePos + stretch * stretchPos;
        vec3 tpos = transform * vec3(pos, 1.0);
        gl_Position = vec4(tpos, 1.0);
        f_texCoord = texCoord;
    }
);

// Luminance-Alpha, swizzled into Red and Green respectively.
static const char* kFragment2 = AP_SHADER(
    uniform float alpha;
    uniform vec4 tint;
    uniform sampler2D texture;
    varying vec2 f_texCoord;
    void main() {
        vec4 pixel = texture2D(texture, f_texCoord).gggr;
        vec3 tinted = mix(pixel.rgb, tint.rgb, tint.a);
        vec4 c = vec4(tinted.rgb, pixel.a * alpha);
        OUTPUT(c);
    }
);

// Normal RGB.
static const char* kFragment3 = AP_SHADER(
    uniform float alpha;
    uniform vec4 tint;
    uniform sampler2D texture;
    varying vec2 f_texCoord;
    void main() {
        vec4 pixel = texture2D(texture, f_texCoord);
        vec3 tinted = mix(pixel.rgb, tint.rgb, tint.a);
        vec4 c = vec4(tinted.rgb, pixel.a * alpha);
        OUTPUT(c);
    }
);

// RGB and alpha in separate textures.
static const char* kFragment4 = AP_SHADER(
    uniform float alpha;
    uniform vec4 tint;
    uniform sampler2D texture;
    uniform sampler2D alphaTexture;
    varying vec2 f_texCoord;
    void main() {
        vec3 pixel = texture2D(texture, f_texCoord).rgb;
        vec3 tinted = mix(pixel, tint.rgb, tint.a);
        float pixelAlpha = texture2D(alphaTexture, f_texCoord).g;
        vec4 c = vec4(tinted.rgb, pixelAlpha * alpha);
        OUTPUT(c);
    }
);

static AP_Image_Program* g_Prog2;
static AP_Image_Program* g_Prog3;
static AP_Image_Program* g_Prog4;

// Contents of the .img file
typedef struct Img {
    uint32_t channels;
    uint32_t iphoneWidth;
    uint32_t iphoneHeight;
    uint32_t ipadWidth;
    uint32_t ipadHeight;
} Img;

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

// This holds the actual GL data. It can vary depending on the tiling.
@interface AP_Image_CacheEntry : NSObject
@property(nonatomic) int numQuads;
@property(nonatomic,strong) AP_GLBuffer* arrayBuffer;
@property(nonatomic,strong) AP_GLBuffer* indexBuffer;
@end

@implementation AP_Image_CacheEntry
@end

@implementation AP_Image {
    AP_Image_Program* _prog;
    AP_GLTexture* _texture;
    AP_GLTexture* _alphaTexture;
    CGSize _size;
    NSMutableData* _quads;
    GLKVector4 _tint;
    CGAffineTransform _imageTransform;

    // Cache of (xTile, yTile) -> AP_Image_CacheEntry
    AP_StrongCache* _cache;
}

- (AP_Image*) CGImage
{
    return self;
}

+ (AP_Image*) imageWithCGImage:(AP_Image*)cgImage scale:(CGFloat)scale orientation:(UIImageOrientation)orientation
{
    return [[AP_Image alloc] initWithCGImage:cgImage scale:scale orientation:orientation];
}

+ (AP_Image*) imageNamed:(NSString*)name
{
    AP_CHECK(name, return nil);
    name = [name stringByDeletingPathExtension];
    NSString* img = [name stringByAppendingString:@".img"];

    static AP_WeakCache* g_ImageCache;
    if (!g_ImageCache) {
        g_ImageCache = [[AP_WeakCache alloc] init];
    }
    AP_CHECK(g_ImageCache, return nil);

    AP_Image* result = [g_ImageCache get:img withLoader:^{
        NSData* data = [AP_Bundle dataForResource:img ofType:nil];
        if (data) {
            return [[AP_Image alloc] initWithName:name data:data];
        }

        AP_GLTexture* texture = [AP_GLTexture textureNamed:name maxSize:2.15];
        if (texture) {
            return [[AP_Image alloc] initWithName:name texture:texture];
        }

        NSLog(@"*** Failed to load image: %@", name);
        return (AP_Image*)nil;
    }];

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

- (instancetype) initWithSize:(CGSize)size scale:(CGFloat)scale
{
    self = [self init];
    if (self) {
        _size = size;
        _scale = scale;
    }
    return self;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        static BOOL initialized = NO;
        if (!initialized) {
            initialized = YES;
            g_Prog2 = [[AP_Image_Program alloc] initWithVertex:kVertex fragment:kFragment2];
            g_Prog3 = [[AP_Image_Program alloc] initWithVertex:kVertex fragment:kFragment3];
            g_Prog4 = [[AP_Image_Program alloc] initWithVertex:kVertex fragment:kFragment4];
        }
        AP_CHECK(g_Prog2, abort());
        AP_CHECK(g_Prog3, abort());
        AP_CHECK(g_Prog4, abort());

        _prog = g_Prog3;
        _insets = UIEdgeInsetsZero;
        _quads = [NSMutableData data];
        _resizingMode = UIImageResizingModeTile;
        _imageTransform = CGAffineTransformIdentity;

        _cache = [[AP_StrongCache alloc] initWithSize:20];
    }
    return self;
}


- (AP_Image*) initWithImage:(AP_Image*)other
{
    AP_CHECK(other, return nil);
    self = [self init];
    if (self) {
        _assetName = other->_assetName;
        _insets = other->_insets;
        _scale = other->_scale;

        _prog = other->_prog;
        _texture = other->_texture;
        _alphaTexture = other->_alphaTexture;
        _size = other->_size;
        _quads = other->_quads;
        _tint = other->_tint;
        _imageTransform = other->_imageTransform;

        // Share the other image's geometry cache!
        // This is safe as long as we reset the cache pointer
        // if any fields change that could affect the cache entries.
        _cache = other->_cache;

        _resizingMode = other->_resizingMode;
    }
    return self;
}

- (AP_Image*) imageWithWidth:(CGFloat)width
{
    return [self imageScaledBy:width / self.size.width];
}

- (AP_Image*) imageScaledBy:(CGFloat)scale
{
    AP_Image* other = [[AP_Image alloc] initWithImage:self];
    other->_scale /= scale;
    return other;
}

- (void) addRaw:(RawQuad)raw
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
    [self addRect:r texPos:texPos];
}

- (void) addStretchy:(StretchyQuad)quad
{
    CGRect r = {
        quad.edge.origin.x + quad.stretch.origin.x,
        quad.edge.origin.y + quad.stretch.origin.y,
        quad.edge.size.width + quad.stretch.size.width,
        quad.edge.size.height + quad.stretch.size.height,
    };
    CGPoint texPos = quad.tex.origin;
    [self addRect:r texPos:texPos];
}

- (void) addRect:(CGRect)r texPos:(CGPoint)texPos
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

            q.tex.origin.x = texPos.x + (q.edge.origin.x + q.stretch.origin.x - r.origin.x) / _size.width;
            q.tex.origin.y = texPos.y + (q.edge.origin.y + q.stretch.origin.y - r.origin.y) / _size.height;
            q.tex.size.width = (q.edge.size.width + q.stretch.size.width) / _size.width;
            q.tex.size.height = (q.edge.size.height + q.stretch.size.height) / _size.height;

            [_quads appendBytes:&q length:sizeof(StretchyQuad)];
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
    return [self resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
}

- (AP_Image*) resizableImageWithCapInsets:(UIEdgeInsets)capInsets
{
    return [[AP_Image alloc] initWithImage:self insets:capInsets];
}

- (AP_Image*) resizableImageWithCapInsets:(UIEdgeInsets)capInsets resizingMode:(UIImageResizingMode)mode
{
    AP_Image* result = [self resizableImageWithCapInsets:capInsets];
    result->_resizingMode = mode;
    return result;
}

- (AP_Image*) initWithImage:(AP_Image*)other insets:(UIEdgeInsets)insets
{
    self = [self init];
    if (self) {
        _assetName = other->_assetName;
        _prog = other->_prog;
        _texture = other->_texture;
        _alphaTexture = other->_alphaTexture;
        _size = other->_size;
        _scale = other->_scale;
        _tint = other->_tint;
        _imageTransform = other->_imageTransform;

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

        int numQuads = other->_quads.length / sizeof(StretchyQuad);
        const StretchyQuad* quads = (const StretchyQuad*) other->_quads.bytes;
        for (int i = 0; i < numQuads; i++) {
            [self addStretchy:quads[i]];
        }

        // Speculative: is "other" being collected by ARC?
        [other self];
    }
//    NSLog(@"Added insets to image: %@", _assetName);
    return self;
}

- (AP_Image*) initWithName:(NSString*)name texture:(AP_GLTexture*)texture
{
    AP_CHECK(name, return nil);
    AP_CHECK(texture, return nil);

    self = [self init];
    if (self) {
        _assetName = name;
        _prog = g_Prog3;
        _texture = texture;
        _size = CGSizeMake(_texture.width, _texture.height);
        _scale = 2.0; // Assume retina texture

        RawQuad q;
        q.x = 0;
        q.y = 0;
        q.xTex = 0;
        q.yTex = 0;
        q.width = _texture.width;
        q.height = _texture.height;

        [self addRaw:q];
    }
//    NSLog(@"Loaded image: %@", name);
    return self;
}

- (AP_Image*) initWithName:(NSString*)name data:(NSData*)data {
    AP_CHECK(name, return nil);
    AP_CHECK(data, return nil);

    AP_CHECK_EQ(sizeof(Img), 20, return nil);

    self = [self init];
    if (self) {
        _assetName = [name stringByDeletingPathExtension];

        // Load header
        const Img* img = (const Img*) data.bytes;

        // Load metrics
        _size = CGSizeMake(2.0 * img->ipadWidth, 2.0 * img->ipadHeight);

        CGFloat ipadScale = sqrtf(img->ipadWidth * img->ipadHeight);
        CGFloat iphoneScale = sqrtf(img->iphoneWidth * img->iphoneHeight);
        _scale = [AP_Window scaleForIPhone:(2.0 * ipadScale / iphoneScale) iPad:2.0];

        switch (img->channels) {
            case 2:
                _prog = g_Prog2;
                break;
            case 4:
                _prog = g_Prog4;
                break;
            default:
                NSLog(@"Warning! Unexpected image channel count: %d", img->channels);
                // fall through
            case 3:
                _prog = g_Prog3;
                break;
        }

        // Load texture name. Look for a .png first.
        NSString* texName = [_assetName stringByAppendingString:@".png"];
        _texture = [AP_GLTexture textureNamed:texName maxSize:2.15];
        if (_texture) {
            // PNG has alpha, so we don't need the separate-alpha shader.
            if (img->channels == 4) {
                _prog = g_Prog3;
            }
        } else {
            // No PNG, look for a KTX file.
            NSString* texName = [_assetName stringByAppendingString:@".ktx"];
            _texture = [AP_GLTexture textureNamed:texName maxSize:2.15];
            AP_CHECK(_texture, return nil);

            // KTX needs separate alpha.
            if (img->channels == 4) {
                NSString* alphaName = [_assetName stringByAppendingString:@".alpha.ktx"];
                _alphaTexture = [AP_GLTexture textureNamed:alphaName maxSize:2.15];
                AP_CHECK(_alphaTexture, return nil);
            }
        }

        RawQuad q;
        q.x = 0;
        q.y = 0;
        q.xTex = 0;
        q.yTex = 0;
        q.width = _size.width;
        q.height = _size.height;

        [self addRaw:q];
    }
//    NSLog(@"Loaded image: %@", name);
    return self;
}

- (instancetype) initWithCGImage:(AP_Image*)cgImage scale:(CGFloat)scale orientation:(UIImageOrientation)orientation
{
    self = [self initWithImage:cgImage];
    if (self) {
        CGAffineTransform t;
        switch (orientation) {
            case UIImageOrientationUp:
                t = CGAffineTransformIdentity;
                break;
            case UIImageOrientationDown:
                t = CGAffineTransformMake(-1, 0, 0, -1, 0, 0);
                break;
            case UIImageOrientationLeft:
                t = CGAffineTransformMake(0, 1, -1, 0, 0, 0);
                break;
            case UIImageOrientationRight:
                t = CGAffineTransformMake(0, -1, 1, 0, 0, 0);
                break;
            case UIImageOrientationUpMirrored:
                t = CGAffineTransformMake(-1, 0, 0, 1, 0, 0);
                break;
            case UIImageOrientationDownMirrored:
                t = CGAffineTransformMake(1, 0, 0, -1, 0, 0);
                break;
            case UIImageOrientationLeftMirrored:
                t = CGAffineTransformMake(0, -1, -1, 0, 0, 0);
                break;
            case UIImageOrientationRightMirrored:
                t = CGAffineTransformMake(0, 1, 1, 0, 0, 0);
                break;
            default:
                NSLog(@"Unknown CGImage orientation: %d", orientation);
                t = CGAffineTransformIdentity;
                break;
        }

        // Move to origin, apply new transform, move back, apply original transform.
        CGFloat x = (_size.width / _scale) / 2;
        CGFloat y = (_size.height / _scale) / 2;
        _imageTransform = CGAffineTransformConcat(
            _imageTransform,
            CGAffineTransformTranslate(
                CGAffineTransformConcat(t,
                    CGAffineTransformMakeTranslation(x, y)),
                -x, -y));

        if (scale != _scale) {
            _scale = scale;
            _cache = [[AP_StrongCache alloc] initWithSize:20];
        }
    }
    return self;
}

- (void) dealloc
{
//    NSLog(@"Deleted image: %@", _assetName);
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

    int cacheKey = (xTile * 1000) + yTile;
    AP_Image_CacheEntry* e = [_cache get:@(cacheKey) withLoader:^{
        // Calculate how many quads we have. This depends on the tiling.
        int numQuads = countTilesInQuads(_quads, xTile, yTile);

        const StretchyQuad* quads = (const StretchyQuad*)(_quads.bytes);
        const StretchyQuad* maxQuad = quads + _quads.length / sizeof(StretchyQuad);

        // Upload the quads as GL triangles.
        // For each quad, we need 4 vertices (24 bytes each) and 6 indices (2 bytes each).
        NSMutableData* vertexData = [NSMutableData dataWithLength:(4 * numQuads * 24)];
        NSMutableData* indexData = [NSMutableData dataWithLength:(6 * numQuads * 2)];
        VertexData* vPtr = (VertexData*) vertexData.bytes;
        GLushort* iPtr = (GLushort*) indexData.bytes;

        int count = 0;
        for (const StretchyQuad* q = quads; q < maxQuad; ++q) {
            // Maybe tile the quad
            int hMax = xTilesInQuad(q, xTile);
            int vMax = yTilesInQuad(q, yTile);
            for (int h = 0; h < hMax; ++h) {
                for (int v = 0; v < vMax; ++v) {
                    // Okay, we finally have a single quad for GL!
                    CGFloat hOrigin = h * stretchSize.width / hMax;
                    CGFloat vOrigin = v * stretchSize.height / vMax;

                    // Need to hack the "stretch" coordinates if we're on the bottom or right edge, ugh
                    if (xTile > 0 && q->stretch.origin.x > 0 && q->stretch.size.width == 0) {
                        hOrigin = (xTile - 1) * stretchSize.width / xTile;
                    }
                    if (yTile > 0 && q->stretch.origin.y > 0 && q->stretch.size.height == 0) {
                        vOrigin = (yTile - 1) * stretchSize.height / yTile;
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
        AP_Image_CacheEntry* result = [[AP_Image_CacheEntry alloc] init];
        result.numQuads = numQuads;
        result.arrayBuffer = [AP_GLBuffer bufferWithTarget:GL_ARRAY_BUFFER usage:GL_STATIC_DRAW data:vertexData];
        result.indexBuffer = [AP_GLBuffer bufferWithTarget:GL_ELEMENT_ARRAY_BUFFER usage:GL_STATIC_DRAW data:indexData];
        return result;
    }];

    transform = CGAffineTransformConcat(_imageTransform, transform);
    transform = CGAffineTransformScale(transform, edgeScale.width / _scale, edgeScale.height / _scale);

    GLKMatrix3 matrix = GLKMatrix3Make(
        transform.a, transform.b, 0,
        transform.c, transform.d, 0,
        transform.tx, transform.ty, 1);

    if (_alphaTexture) {
        _GL(ActiveTexture, GL_TEXTURE1);
        _GL(BindTexture, GL_TEXTURE_2D, _alphaTexture.name);
    }

    _GL(ActiveTexture, GL_TEXTURE0);
    _GL(BindTexture, GL_TEXTURE_2D, _texture.name);

    [_prog use];
    [e.arrayBuffer bind];
    [e.indexBuffer bind];

    _GL(Uniform1i, _prog.texture, 0);
    if (_alphaTexture) {
        _GL(Uniform1i, _prog.alphaTexture, 1);
    }
    _GL(Uniform1f, _prog.alpha, alpha);
    _GL(UniformMatrix3fv, _prog.transform, 1, false, matrix.m);
    _GL(Uniform2f, _prog.stretch, stretchScale.width, stretchScale.height);
    _GL(Uniform4fv, _prog.tint, 1, _tint.v);

    _GL(EnableVertexAttribArray, _prog.edgePos);
    _GL(EnableVertexAttribArray, _prog.stretchPos);
    _GL(EnableVertexAttribArray, _prog.texCoord);
    _GL(VertexAttribPointer, _prog.edgePos, 2, GL_FLOAT, false, 24, 0);
    _GL(VertexAttribPointer, _prog.stretchPos, 2, GL_FLOAT, false, 24, (void*)8);
    _GL(VertexAttribPointer, _prog.texCoord, 2, GL_FLOAT, false, 24, (void*)16);

    _GL(DrawElements, GL_TRIANGLES, 6 * e.numQuads, GL_UNSIGNED_SHORT, 0);

    _GL(DisableVertexAttribArray, _prog.edgePos);
    _GL(DisableVertexAttribArray, _prog.stretchPos);
    _GL(DisableVertexAttribArray, _prog.texCoord);

    [e.arrayBuffer unbind];
    [e.indexBuffer unbind];
}

- (AP_Image*) tintedImageUsingColor:(UIColor*)tintColor
{
    AP_Image* result = [[AP_Image alloc] initWithImage:self];
    result->_tint = AP_ColorToVector(tintColor);
    return result;
}

@end
