#import "AP_GLTexture_PNG.h"

#import <UIKit/UIKit.h>

#import "stb_image.h"
#import "stb_image_resize.h"

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

+ (BOOL) isPNG:(NSData*)data
{
    AP_CHECK(data, return NO);
    return ([data length] > 9) && (0 == memcmp([data bytes], gPNGIdentifier, 8));
}

- (BOOL) loadPNG:(NSData*)data
{
    int w, h, c;
    int success = stbi_info_from_memory([data bytes], [data length], &w, &h, &c);
    if (!success) {
        NSLog(@"Error loading PNG: %s", stbi_failure_reason());
        return NO;
    }

    const int wantedComponents = c;

    unsigned char* bytes = stbi_load_from_memory([data bytes], [data length], &w, &h, &c, wantedComponents);
    AP_CHECK(bytes, return NO);
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

    [self texImage2dLevel:0 format:format width:w height:h type:GL_UNSIGNED_BYTE data:(const char*)bytes];
    stbi_image_free(bytes);

#ifdef SORCERY_SDL
    const BOOL mipmaps = YES;
#else
    // glGenerateMipmap() doesn't work properly on the Kindle Fire, bah!
    // It seems to work for LUMINANCE textures and square textures. Maybe
    // it's only broken for non-square textures? (e.g. gradients)
    const BOOL mipmaps = (w == h);
#endif
     if (mipmaps) {
        _GL(GenerateMipmap, GL_TEXTURE_2D);
        self.memoryUsage = (4 * self.memoryUsage) / 3;
        _GL(TexParameteri, self.textureTarget, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        _GL(TexParameteri, self.textureTarget, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
     } else {
         _GL(TexParameteri, self.textureTarget, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
         _GL(TexParameteri, self.textureTarget, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
     }

    AP_CHECK_GL("Failed to upload PNG texture", return NO);

    return YES;
}

@end
