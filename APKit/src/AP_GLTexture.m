#import "AP_GLTexture.h"

#import <math.h>

#import "AP_Bundle.h"
#import "AP_Check.h"
#import "AP_GLTexture_KTX.h"
#import "AP_GLTexture_PNG.h"
#import "AP_GLTexture_PVR.h"
#import "AP_WeakCache.h"
#import "AP_Window.h"

@implementation AP_GLTexture {
    GLuint _name;
    int _width;
    int _height;
    int _minLevel;
    int _maxTextureSize;
}

static int s_totalMemoryUsage = 0;
static NSMutableArray* s_deleteQueue = nil;

+ (void) processDeleteQueue
{
    for (NSNumber* n in s_deleteQueue) {
        GLuint name = n.intValue;
        glDeleteTextures(1, &name);
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

+ (AP_GLTexture*) textureNamed:(NSString*)name limitSize:(BOOL)limitSize
{
    static AP_WeakCache* g_TextureCache;
    if (!g_TextureCache) {
        g_TextureCache = [[AP_WeakCache alloc] init];
    }
    AP_CHECK(g_TextureCache, return nil);

    AP_GLTexture* result = [g_TextureCache get:name withLoader:^{
        NSData* data = [AP_Bundle dataForResource:name ofType:nil];
        AP_GLTexture* result = [AP_GLTexture textureWithData:data limitSize:limitSize];
        if (result) {
            result->_assetName = name;
            int bytes = result->_memoryUsage;
            s_totalMemoryUsage += bytes;
            NSLog(@"Loaded %@ (%d bytes)", name, bytes);
        } else {
            NSLog(@"Failed to load texture: %@", name);
        }
        return result;
    }];

    AP_CHECK([result isKindOfClass:[AP_GLTexture class]], abort());
    return result;
}

+ (AP_GLTexture*) textureWithContentsOfFile:(NSString*)path limitSize:(BOOL)limitSize
{
    NSData* data = [NSData dataWithContentsOfMappedFile:path];
    return [AP_GLTexture textureWithData:data limitSize:limitSize];
}

+ (AP_GLTexture*) textureWithData:(NSData*)data limitSize:(BOOL)limitSize
{
    AP_CHECK(data, return nil);
    if ([AP_GLTexture_PVR isPVR:data]) {
        return [AP_GLTexture_PVR withData:data];
    } else if ([AP_GLTexture_KTX isKTX:data]) {
        return [AP_GLTexture_KTX withData:data limitSize:limitSize];
    } else if ([AP_GLTexture_PNG isPNG:data]) {
        return [AP_GLTexture_PNG withData:data];
    } else {
        NSLog(@"Texture is in unknown format!");
        return nil;
    }
}

+ (int) totalMemoryUsage
{
    return s_totalMemoryUsage;
}

- (AP_GLTexture*) init
{
    return [self initLimitSize:NO];
}

- (AP_GLTexture*) initLimitSize:(BOOL)limitSize
{
#ifndef ANDROID
    AP_CHECK([EAGLContext currentContext], return nil);
#endif
    self = [super init];
    if (self) {
        static GLint systemMaxTextureSize = 0;
        if (systemMaxTextureSize == 0) {
            glGetIntegerv(GL_MAX_TEXTURE_SIZE, &systemMaxTextureSize);
        }
        _maxTextureSize = systemMaxTextureSize;
#ifdef ANDROID
        if (limitSize) {
            CGSize s = [AP_Window screenSize];
            CGFloat screenSize = MAX(s.width, s.height) * [AP_Window screenScale];
            CGFloat screenMaxTextureSize = [UIApplication sharedApplication].isCrappyDevice
                ? screenSize * 1.59  // Use 1024 texture for screens up to 1280 pixels in size
                : screenSize * 1.99; // Use 1024 texture for screens up to 1024 pixels in size
            _maxTextureSize = MIN(systemMaxTextureSize, screenMaxTextureSize);
        }
#endif
        glGenTextures(1, &_name);
        AP_CHECK(_name, return nil);
        _width = _height = 0;
    }
    return self;
}

- (GLuint) name { return _name; }
- (int) width { return _width; }
- (int) height { return _height; }

- (void) bind
{
    glBindTexture(GL_TEXTURE_2D, _name);
}

- (void) maybeUpdateWidth:(GLsizei)width height:(GLsizei)height level:(GLint)level
{
    if (level == 0) {
        _width = width;
        _height = height;
    }
    if (width > _maxTextureSize || height > _maxTextureSize) {
//        NSLog(@"Mipmap level %d is too big (%d x %d, max texture size: %d)", level, width, height, _maxTextureSize);
        _minLevel = MAX(_minLevel, level + 1);
    }
}

- (void) texImage2dLevel:(GLint)level format:(GLint)format width:(GLsizei)width height:(GLsizei)height type:(GLenum)type data:(const char*)data
{
    [self bind];
    [self maybeUpdateWidth:width height:height level:level];

    if (level >= _minLevel) {
        glTexImage2D(GL_TEXTURE_2D, level - _minLevel, format, width, height, 0, format, type, data);

        switch (format) {
            case GL_LUMINANCE:
                _memoryUsage += width * height;
                break;
            case GL_LUMINANCE_ALPHA:
                _memoryUsage += 2 * width * height;
                break;
            case GL_RGB:
                _memoryUsage += 3 * width * height;
                break;
            case GL_RGBA:
                _memoryUsage += 4 * width * height;
                break;
            default:
                NSLog(@"Unknown texture format: %d", format);
                break;
        }
    }
}

- (void) compressedTexImage2dLevel:(GLint)level format:(GLenum)format width:(GLsizei)width height:(GLsizei)height data:(const char*)data dataSize:(size_t)dataSize
{
    [self bind];
    [self maybeUpdateWidth:width height:height level:level];

    if (level >= _minLevel) {
        glCompressedTexImage2D(GL_TEXTURE_2D, level - _minLevel, format, width, height, 0, dataSize, data);
        _memoryUsage += dataSize;
    }
}

@end
