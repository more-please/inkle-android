#import "AP_GLTexture.h"

#import <math.h>

#import "AP_Bundle.h"
#import "AP_Cache.h"
#import "AP_Check.h"
#import "AP_GLTexture_KTX.h"
#import "AP_GLTexture_PNG.h"
#import "AP_GLTexture_PVR.h"

@implementation AP_GLTexture {
    GLuint _name;
    int _width;
    int _height;
    int _minLevel;
}

+ (AP_GLTexture*) textureNamed:(NSString*)name
{
    static AP_Cache* g_TextureCache;
    if (!g_TextureCache) {
        g_TextureCache = [[AP_Cache alloc] init];
    }
    AP_CHECK(g_TextureCache, return nil);

    AP_GLTexture* result = [g_TextureCache get:name withLoader:^{
        NSData* data = [AP_Bundle dataForResource:name ofType:nil];
        AP_GLTexture* result = [AP_GLTexture textureWithData:data];
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

+ (AP_GLTexture*) textureWithContentsOfFile:(NSString*)path
{
    NSData* data = [NSData dataWithContentsOfMappedFile:path];
    return [AP_GLTexture textureWithData:data];
}

+ (AP_GLTexture*) textureWithData:(NSData*)data
{
    AP_CHECK(data, return nil);
    if ([AP_GLTexture_PVR isPVR:data]) {
        return [AP_GLTexture_PVR withData:data];
    } else if ([AP_GLTexture_KTX isKTX:data]) {
        return [AP_GLTexture_KTX withData:data];
    } else if ([AP_GLTexture_PNG isPNG:data]) {
        return [AP_GLTexture_PNG withData:data];
    } else {
        NSLog(@"Texture is in unknown format!");
        return nil;
    }
}

- (AP_GLTexture*) init
{
#ifndef ANDROID
    AP_CHECK([EAGLContext currentContext], return nil);
#endif
    self = [super init];
    if (self) {
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
    static GLint maxTextureSize = 0;
    if (maxTextureSize == 0) {
        glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
    }
    if (width > maxTextureSize || height > maxTextureSize) {
        NSLog(@"Mipmap level %d is too big (%d x %d, max texture size: %d)", level, width, height, maxTextureSize);
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
