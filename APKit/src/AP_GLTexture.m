#import "AP_GLTexture.h"

#import <math.h>

#import "AP_Bundle.h"
#import "AP_Check.h"
#import "AP_GL.h"
#import "AP_GLTexture_CRN.h"
#import "AP_GLTexture_KTX.h"
#import "AP_GLTexture_PNG.h"
#import "AP_GLTexture_PVR.h"
#import "AP_WeakCache.h"
#import "AP_Window.h"

@implementation AP_GLTexture {
    int _face;
}

static int s_totalMemoryUsage = 0;
static NSMutableArray* s_deleteQueue = nil;
static AP_WeakCache* s_textureCache = nil;

+ (void) initialize
{
    if (!s_textureCache) {
        s_textureCache = [[AP_WeakCache alloc] init];
    }
}

+ (void) processDeleteQueue
{
    for (NSNumber* n in s_deleteQueue) {
        GLuint name = n.intValue;
        _GL(DeleteTextures, 1, &name);
    }
    s_deleteQueue = nil;
}

- (void) dealloc
{
    NSLog(@"Deleted %@ (%d bytes)", _assetName, _memoryUsage);
    s_totalMemoryUsage -= _memoryUsage;
    if (!s_deleteQueue) {
        s_deleteQueue = [[NSMutableArray alloc] init];
    }
    [s_deleteQueue addObject:[NSNumber numberWithInt:_name]];
}

- (BOOL) loadData:(NSData*)data
{
    AP_CHECK_GL(@"before [AP_GLTexture loadData]", /* ignore error and carry on */);

    int oldMemoryUsage = _memoryUsage;
    BOOL success;
    if ([AP_GLTexture isPVR:data]) {
        success = [self loadPVR:data];
    } else if ([AP_GLTexture isKTX:data]) {
        success = [self loadKTX:data];
    } else if ([AP_GLTexture isCRN:data]) {
        success = [self loadCRN:data];
    } else if ([AP_GLTexture isPNG:data]) {
        success = [self loadPNG:data];
    } else {
        NSLog(@"Texture is in unknown format!");
        success = NO;
    }

    s_totalMemoryUsage += (_memoryUsage - oldMemoryUsage);

    AP_CHECK_GL(@"after [AP_GLTexture loadData]", /* ignore error and carry on */);

    return success;
}

+ (AP_GLTexture*) textureNamed:(NSString*)name
{
    AP_CHECK(name, return nil);
    AP_CHECK(s_textureCache, return nil);
    AP_GLTexture* result = [s_textureCache get:name withLoader:^{
        NSData* data = nil;
        NSString* assetName = name;
        if (assetName.pathExtension.length > 0) {
            // Name has a path extension, load this exact texture
            data = [AP_Bundle dataForResource:assetName ofType:nil];
        } else {
            // No path extension, try both .png and .ktx
            if (!data) {
                assetName = [name stringByAppendingPathExtension:@"png"];
                data = [AP_Bundle dataForResource:assetName ofType:nil];
            }
            if (!data) {
                assetName = [name stringByAppendingPathExtension:@"ktx"];
                data = [AP_Bundle dataForResource:assetName ofType:nil];
            }
            if (!data) {
                assetName = [name stringByAppendingPathExtension:@"crn"];
                data = [AP_Bundle dataForResource:assetName ofType:nil];
            }
        }
        AP_GLTexture* result = nil;
        if (data) {
            result = [AP_GLTexture textureWithName:assetName data:data];
        }
        if (result) {
            NSLog(@"Loaded %@ (%d bytes)", assetName, result.memoryUsage);
        }
        return result;
    }];

    if (!result) {
        NSLog(@"*** Failed to load texture: %@", name);
    }
    return result;
}

+ (AP_GLTexture*) cubeTextureNamed:(NSString*)name
{
    AP_CHECK(s_textureCache, return nil);
    AP_GLTexture* result = [s_textureCache get:name withLoader:^{
        NSString* faceExt[6] = {
            @"left", // GL_TEXTURE_CUBE_MAP_POSITIVE_X
            @"right", // GL_TEXTURE_CUBE_MAP_NEGATIVE_X
            @"up", // GL_TEXTURE_CUBE_MAP_POSITIVE_Y
            @"down", // GL_TEXTURE_CUBE_MAP_NEGATIVE_Y
            @"front", // GL_TEXTURE_CUBE_MAP_POSITIVE_Z
            @"back"  // GL_TEXTURE_CUBE_MAP_NEGATIVE_Z
        };
        NSString* base = [name stringByDeletingPathExtension];
        NSString* ext = name.pathExtension;

        AP_GLTexture* result = [[AP_GLTexture alloc] initWithName:name target:GL_TEXTURE_CUBE_MAP];
        for (int f = 0; f < 6; ++f) {
            result->_face = f;
            NSString* faceName = [NSString stringWithFormat:@"%@_%@.%@", base, faceExt[f], ext];
            NSData* data = [AP_Bundle dataForResource:faceName ofType:nil];
            if (!data) {
                NSLog(@"Missing cube face: %@", faceName);
                result = nil;
                break;
            }
            if (![result loadData:data]) {
                NSLog(@"Failed to load face: %@", faceName);
                result = nil;
                break;
            }
        }
        return result;
    }];

    if (!result) {
        NSLog(@"Failed to load cube texture: %@", name);
        return nil;
    }

    NSLog(@"Loaded %@ (cube, %d bytes)", name, result.memoryUsage);
    return result;
}

+ (AP_GLTexture*) textureWithName:(NSString*)name data:(NSData*)data
{
    if (!data) {
        return nil;
    }
    AP_GLTexture* result = [[AP_GLTexture alloc] initWithName:name target:GL_TEXTURE_2D];
    if ([result loadData:data]) {
        return result;
    } else {
        return nil;
    }
}

+ (int) totalMemoryUsage
{
    return s_totalMemoryUsage;
}

- (AP_GLTexture*) initWithName:(NSString*)name target:(GLenum)target
{
    self = [super init];
    if (self) {
        _assetName = name;
        _width = _height = 0;
        _textureTarget = target;

        _GL(GenTextures, 1, &_name);
        AP_CHECK(_name, return nil);

        _GL(BindTexture, _textureTarget, _name);
        _GL(TexParameteri, _textureTarget, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        _GL(TexParameteri, _textureTarget, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    return self;
}

- (BOOL) cube
{
    return _textureTarget == GL_TEXTURE_CUBE_MAP;
}

- (void) bind
{
    _GL(BindTexture, _textureTarget, _name);
}

#ifndef GL_LUMINANCE
#define GL_LUMINANCE 0x1909
#endif

#ifndef GL_LUMINANCE_ALPHA
#define GL_LUMINANCE_ALPHA 0x190A
#endif

#ifndef GL_RG
#define GL_RG 0x8227
#endif

#ifndef GL_R8
#define GL_R8 0x8229
#endif

#ifndef GL_RG8
#define GL_RG8 0x822B
#endif

#ifndef GL_RGBA8
#define GL_RGBA8 0x8058
#endif

#ifndef GL_RED
#define GL_RED 0x1903
#endif

#ifndef GL_GREEN
#define GL_GREEN 0x1904
#endif

#ifndef GL_TEXTURE_SWIZZLE_RGBA
#define GL_TEXTURE_SWIZZLE_RGBA 0x8E46
#endif

static BOOL isPowerOfTwo(int n) {
    return 0 == (n & (n-1));
}

- (void) texImage2dLevel:(GLint)level format:(GLint)format width:(GLsizei)width height:(GLsizei)height type:(GLenum)type data:(const char*)data
{
    [self bind];

    if (!_width || !_height) {
        _width = width;
        _height = height;
    }

    GLenum target = self.cube ? (GL_TEXTURE_CUBE_MAP_POSITIVE_X + _face) : GL_TEXTURE_2D;

    GLint internalFormat = AP_GLES_2_3(format, GL_RGBA, GL_RGBA8);

    switch (format) {
        case GL_ALPHA:
        case GL_LUMINANCE:
        case GL_RED: {
            _memoryUsage += width * height;
            internalFormat = AP_GLES_2_3(format, GL_LUMINANCE, GL_R8);
            if (g_AP_GL == AP_GL3) {
                GLint const kSwizzle[4] = { GL_RED, GL_RED, GL_RED, GL_ONE };
                _GL(TexParameteriv, target, GL_TEXTURE_SWIZZLE_RGBA, kSwizzle);
            }
            break;
        }
        case GL_LUMINANCE_ALPHA:
        case GL_RG: {
            _memoryUsage += 2 * width * height;
            internalFormat = AP_GLES_2_3(format, GL_LUMINANCE_ALPHA, GL_RG8);
            if (g_AP_GL == AP_GL3) {
                GLint const kSwizzle[4] = { GL_RED, GL_RED, GL_RED, GL_GREEN };
                _GL(TexParameteriv, target, GL_TEXTURE_SWIZZLE_RGBA, kSwizzle);
            }
            break;
        }
        case GL_RGB:
            switch (type) {
                case GL_UNSIGNED_BYTE:
                    _memoryUsage += 3 * width * height;
                    break;
                case GL_UNSIGNED_SHORT_5_6_5:
                    _memoryUsage += 2 * width * height;
                default:
                    NSLog(@"Unknown GL_RGB texture type: %d", type);
                    break;
            }
            break;
        case GL_RGBA:
            switch (type) {
                case GL_UNSIGNED_BYTE:
                    _memoryUsage += 4 * width * height;
                    break;
                case GL_UNSIGNED_SHORT_4_4_4_4:
                case GL_UNSIGNED_SHORT_5_5_5_1:
                    _memoryUsage += 2 * width * height;
                    break;
                default:
                    NSLog(@"Unknown GL_RGBA texture type: %d", type);
                    break;
            }
            break;
        default:
            NSLog(@"Unknown texture format: %d", format);
            break;
    }

    if (!isPowerOfTwo(width) || !isPowerOfTwo(height)) {
        NSLog(@"NPOT texture - glTexImage2D(0x%x, %d, 0x%x, %d, %d, %d, 0x%x, 0x%x, %p)",
            target, level, internalFormat, width, height, 0, format, type, data);
    }

    _GL(TexImage2D, target, level, internalFormat, width, height, 0, format, type, data);
    AP_CHECK_GL(@"glTexImage2D", /* ignore error and carry on */);
}

- (void) compressedTexImage2dLevel:(GLint)level format:(GLenum)format width:(GLsizei)width height:(GLsizei)height data:(const char*)data dataSize:(size_t)dataSize
{
    [self bind];

    if (!_width || !_height) {
        _width = width;
        _height = height;
    }

    GLenum target = self.cube ? (GL_TEXTURE_CUBE_MAP_POSITIVE_X + _face) : GL_TEXTURE_2D;

    if (!isPowerOfTwo(width) || !isPowerOfTwo(height)) {
        NSLog(@"NPOT texture - glCompressedTexImage2D(0x%x, %d, 0x%x, %d, %d, %d, %d, %p)",
            target, level, format, width, height, 0, (int) dataSize, data);
    }

    _GL(CompressedTexImage2D, target, level, format, width, height, 0, dataSize, data);
    _memoryUsage += dataSize;

    AP_CHECK_GL(@"glCompressedTexImage2D", /* ignore error and carry on */);
}

- (void) fixWidth:(int)w height:(int)h
{
    _width = w;
    _height = h;
}

@end
