#pragma once

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>

// Simple wrapper for a GL texture object.
// The texture is initially empty. Before using it, texImage2d or compressedTexImage2D to upload texture data.

@interface AP_GLTexture : NSObject

@property (nonatomic,readonly) NSString* assetName;
@property (nonatomic,readonly) GLuint name;
@property (nonatomic,readonly) GLenum textureTarget;
@property (nonatomic,readonly) BOOL cube;
@property (nonatomic,readonly) int width;
@property (nonatomic,readonly) int height;
@property (nonatomic) int memoryUsage;

- (void) bind;

// Load a texture resource (via AP_Bundle).
// The results are cached, so the same object may be returned in subsequent calls.
+ (AP_GLTexture*) textureNamed:(NSString*)name;

+ (AP_GLTexture*) cubeTextureNamed:(NSString*)name;

// Estimated total memory usage for all textures.
+ (int) totalMemoryUsage;

+ (void) processDeleteQueue;

// Internal methods

- (void) texImage2dLevel:(GLint)level format:(GLint)format width:(GLsizei)width height:(GLsizei)height type:(GLenum)type data:(const char*)data;
- (void) compressedTexImage2dLevel:(GLint)level format:(GLenum)format width:(GLsizei)width height:(GLsizei)height data:(const char*)data dataSize:(size_t)dataSize;

- (void) fixWidth:(int)w height:(int)h;

@end
