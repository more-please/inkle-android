#import "AP_GLTexture_PNG.h"

#import <UIKit/UIKit.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
#pragma clang diagnostic ignored "-Wunused-value"
#pragma clang diagnostic ignored "-Wunused-variable"

#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_STATIC
#define STBI_ONLY_PNG

#import "stb_image.h"

#define STB_IMAGE_RESIZE_IMPLEMENTATION
#define STB_IMAGE_RESIZE_STATIC

#import "stb_image_resize.h"

#ifdef SORCERY_SDL
#define STB_DXT_IMPLEMENTATION
#import "stb_dxt.h"
#endif

#pragma clang diagnostic pop

#import "AP_Check.h"
#import "AP_GL.h"

static char gPNGIdentifier[8] = "\x89PNG\r\n\x1A\n";

@implementation AP_GLTexture (PNG)

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

#ifndef GL_RED
#define GL_RED 0x1903
#endif

#ifndef GL_COMPRESSED_RGB_S3TC_DXT1_EXT
#define GL_COMPRESSED_RGB_S3TC_DXT1_EXT                         0x83F0
#define GL_COMPRESSED_RGBA_S3TC_DXT1_EXT                        0x83F1
#define GL_COMPRESSED_RGBA_S3TC_DXT3_EXT                        0x83F2
#define GL_COMPRESSED_RGBA_S3TC_DXT5_EXT                        0x83F3
#endif

+ (BOOL) isPNG:(NSData*)data
{
    AP_CHECK(data, return NO);
    return ([data length] > 9) && (0 == memcmp([data bytes], gPNGIdentifier, 8));
}

#ifdef SORCERY_SDL
static void extract_dxt_block(uint8_t dest[64], const uint8_t* src, int w, int h, int x, int y) {
    int stride = w * 4;
    for (int dy = 0; dy < 4; ++dy) {
        for (int dx = 0; dx < 4; ++dx) {
            for (int c = 0; c < 4; ++c) {
                dest[16 * dy + 4*dx + c] = src[stride * MIN(h - 1, y + dy) + 4 * MIN(w - 1, x + dx) + c];
            }
        }
    }
}

static size_t compress_dxt1(uint8_t* dest, const uint8_t* src, int w, int h) {
    uint8_t block[64];
    uint8_t* start = dest;
    for (int y = 0; y < h; y += 4) {
        for (int x = 0; x < w; x += 4) {
            extract_dxt_block(block, src, w, h, x, y);
            stb_compress_dxt_block(dest, block, 0, STB_DXT_HIGHQUAL);
            dest += 8;
        }
    }
    return dest - start;
}

static size_t compress_dxt5(uint8_t* dest, const uint8_t* src, int w, int h) {
    uint8_t block[64];
    uint8_t* start = dest;
    for (int y = 0; y < h; y += 4) {
        for (int x = 0; x < w; x += 4) {
            extract_dxt_block(block, src, w, h, x, y);
            stb_compress_dxt_block(dest, block, 1, STB_DXT_HIGHQUAL);
            dest += 16;
        }
    }
    return dest - start;
}
#endif

- (BOOL) loadPNG:(NSData*)data
{
    int w, h, c;
    int success = stbi_info_from_memory([data bytes], [data length], &w, &h, &c);
    if (!success) {
        NSLog(@"Error loading PNG: %s", stbi_failure_reason());
        return NO;
    }

    const int wantedComponents = 4;

    unsigned char* bytes = stbi_load_from_memory([data bytes], [data length], &w, &h, &c, wantedComponents);
    if (!bytes) {
        NSLog(@"Error decoding PNG: %s", stbi_failure_reason());
        return NO;
    }

    GLenum format = GL_RGBA;
    switch (wantedComponents) {
        case 1:
            format = AP_GLES_2_3(GL_LUMINANCE, GL_LUMINANCE, GL_RED);
            break;
        case 2:
            format = AP_GLES_2_3(GL_LUMINANCE_ALPHA, GL_LUMINANCE_ALPHA, GL_RG);
            break;
        case 3:
            format = GL_RGB;
            break;
        case 4:
            format = GL_RGBA;
            break;
    }

    [self fixWidth:w height:h];
    if ([UIApplication sharedApplication].isCrappyDevice && w > 1024 && h > 1024) {
        int w2 = w / 2;
        int h2 = h / 2;
        unsigned char* bytes2 = malloc(w2 * h2 * wantedComponents);

        NSLog(@"Reducing PNG from %dx%d -> %dx%d...", w, h, w2, h2);
        stbir_resize_uint8(bytes, w, h, 0, bytes2, w2, h2, 0, wantedComponents);
        NSLog(@"Reducing PNG from %dx%d -> %dx%d... Done", w, h, w2, h2);

        stbi_image_free(bytes);

        bytes = bytes2;
        w = w2;
        h = h2;
    }

    const BOOL pot = ((w & (w-1)) == 0) && ((h & (h-1)) == 0);
    const BOOL square = (w == h);
    const BOOL mipmaps = pot && square;

    if (!mipmaps) {
        [self texImage2dLevel:0 format:format width:w height:h type:GL_UNSIGNED_BYTE data:(const char*)bytes];
         _GL(TexParameteri, self.textureTarget, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
         _GL(TexParameteri, self.textureTarget, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        stbi_image_free(bytes);
        return YES;
    }

    unsigned char* bytes2 = malloc(w * h * wantedComponents);

    for (int level = 0; ; ++level){
        NSLog(@"Generating mipmap %d (%dx%d)", level, w, h);
#ifdef SORCERY_SDL
        size_t size;
        GLenum format;
        if (c == 4 || c == 2) {
            size = compress_dxt5(bytes2, bytes, w, h);
            format = GL_COMPRESSED_RGBA_S3TC_DXT5_EXT;
        } else {
            size = compress_dxt1(bytes2, bytes, w, h);
            format = GL_COMPRESSED_RGB_S3TC_DXT1_EXT;
        }
        [self compressedTexImage2dLevel:level format:format width:w height:h data:(const char*)bytes2 dataSize:size];
#else
        [self texImage2dLevel:level format:format width:w height:h type:GL_UNSIGNED_BYTE data:(const char*)bytes];
#endif
        if (w == 1 || h == 1) {
            break;
        }

        // Generate the next mipmap
        int w2 = w / 2;
        int h2 = h / 2;

        stbir_resize_uint8(bytes, w, h, 0, bytes2, w2, h2, 0, wantedComponents);

        unsigned char* tmp = bytes2;
        bytes2 = bytes;
        bytes = tmp;

        w = w2;
        h = h2;
    }

    _GL(TexParameteri, self.textureTarget, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    _GL(TexParameteri, self.textureTarget, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);

    stbi_image_free(bytes);
    stbi_image_free(bytes2);
    return YES;
}

@end
