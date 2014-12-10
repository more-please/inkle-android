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
    int _minLevel;
    int _maxTextureSize;
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
    int oldMemoryUsage = _memoryUsage;
    BOOL success;
    if ([AP_GLTexture isPVR:data]) {
        success = [self loadPVR:data];
    } else if ([AP_GLTexture isKTX:data]) {
        success = [self loadKTX:data];
    } else if ([AP_GLTexture isPNG:data]) {
        success = [self loadPNG:data];
    } else {
        NSLog(@"Texture is in unknown format!");
        success = NO;
    }
    if (success) {
        s_totalMemoryUsage += (_memoryUsage - oldMemoryUsage);
    }
    return success;
}

+ (AP_GLTexture*) textureNamed:(NSString*)name maxSize:(CGFloat)screens
{
    AP_CHECK(s_textureCache, return nil);
    AP_GLTexture* result = [s_textureCache get:name withLoader:^{
        NSData* data = [AP_Bundle dataForResource:name ofType:nil];
        return [AP_GLTexture textureWithName:name data:data maxSize:screens];
    }];

    if (!result) {
        NSLog(@"Failed to load texture: %@", name);
        return nil;
    }

    _GL(TexParameteri, GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    _GL(TexParameteri, GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    NSLog(@"Loaded %@ (%d bytes)", name, result.memoryUsage);
    return result;
}

+ (AP_GLTexture*) textureWithContentsOfFile:(NSString*)path maxSize:(CGFloat)screens
{
    NSData* data = [NSData dataWithContentsOfMappedFile:path];
    return [AP_GLTexture textureWithData:data maxSize:screens];
}

+ (AP_GLTexture*) textureWithName:(NSString*)name data:(NSData*)data maxSize:(CGFloat)screens
{
    AP_CHECK(data, return nil);
    AP_GLTexture* result = [[AP_GLTexture alloc] initWithName:name maxSize:screens];
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

- (AP_GLTexture*) initWithName:(NSString*)name maxSize:(CGFloat)screens
{
#ifndef ANDROID
    AP_CHECK([EAGLContext currentContext], return nil);
#endif
    self = [super init];
    if (self) {
        _assetName = name;
        _width = _height = 0;
        _minLevel = 0;
        _textureTarget = GL_TEXTURE_2D;

        static GLint systemMaxTextureSize = 0;
        if (systemMaxTextureSize == 0) {
            _GL(GetIntegerv, GL_MAX_TEXTURE_SIZE, &systemMaxTextureSize);
        }
        _maxTextureSize = systemMaxTextureSize;
#ifdef ANDROID
        CGSize s = [AP_Window screenSize];
        CGFloat screenSize = MAX(s.width, s.height) * [AP_Window screenScale];
        CGFloat screenMaxTextureSize = screenSize * screens;
        _maxTextureSize = MIN(systemMaxTextureSize, screenMaxTextureSize);
#endif
        _GL(GenTextures, 1, &_name);
        AP_CHECK(_name, return nil);
    }
    return self;
}

- (void) bind
{
    _GL(BindTexture, GL_TEXTURE_2D, _name);
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
        _GL(TexImage2D, _textureTarget, level - _minLevel, format, width, height, 0, format, type, data);

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
        _GL(CompressedTexImage2D, _textureTarget, level - _minLevel, format, width, height, 0, dataSize, data);
        _memoryUsage += dataSize;
    }
}

@end
