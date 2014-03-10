#import "AP_GLTexture.h"

#import <math.h>

#import "AP_Bundle.h"
#import "AP_Cache.h"
#import "AP_Check.h"
#import "AP_GLTexture_KTX.h"
#import "AP_GLTexture_PNG.h"
#import "AP_GLTexture_PVR.h"
#import "AP_Window.h"

@implementation AP_GLTexture {
    GLuint _name;
    int _width;
    int _height;
    int _minLevel;
    int _maxTextureSize;
}

+ (AP_GLTexture*) textureNamed:(NSString*)name limitSize:(BOOL)limitSize
{
    static AP_Cache* g_TextureCache;
    if (!g_TextureCache) {
        g_TextureCache = [[AP_Cache alloc] initWithSize:5];
    }
    AP_CHECK(g_TextureCache, return nil);

    AP_GLTexture* result = [g_TextureCache get:name withLoader:^{
        NSData* data = [AP_Bundle dataForResource:name ofType:nil];
        AP_GLTexture* result = [AP_GLTexture textureWithData:data limitSize:limitSize];
        if (result) {
            result->_assetName = name;
            NSLog(@"Loaded texture: %@", name);
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
        if (limitSize) {
            CGSize s = [AP_Window screenSize];
            CGFloat screenSize = MAX(s.width, s.height) * [AP_Window screenScale];
            _maxTextureSize = MIN(systemMaxTextureSize, screenSize * 2);
        } else {
            _maxTextureSize = systemMaxTextureSize;
        }

        glGenTextures(1, &_name);
        AP_CHECK(_name, return nil);
        _width = _height = 0;
    }
    return self;
}

- (void) dealloc
{
    NSLog(@"Deleting texture: %@", _assetName);
    glDeleteTextures(1, &_name);
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
    }
}

- (void) compressedTexImage2dLevel:(GLint)level format:(GLenum)format width:(GLsizei)width height:(GLsizei)height data:(const char*)data dataSize:(size_t)dataSize
{
    [self bind];
    [self maybeUpdateWidth:width height:height level:level];

    if (level >= _minLevel) {
        glCompressedTexImage2D(GL_TEXTURE_2D, level - _minLevel, format, width, height, 0, dataSize, data);
    }
}

@end
