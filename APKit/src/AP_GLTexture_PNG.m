#import "AP_GLTexture_PNG.h"

#import "stb_image.h"

#import "AP_Check.h"

static char gPNGIdentifier[8] = "\x89PNG\r\n\x1A\n";

@implementation AP_GLTexture (PNG)

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

#ifdef SORCERY_SDL
    // Desktop GL: expand all textures to full RGBA.
    // 1- and 2-component textures are broken, and I can't figure out how to load 3-component data directly.
    const int wantedComponents = 4;
#else
    const int wantedComponents = c;
#endif

    unsigned char* bytes = stbi_load_from_memory([data bytes], [data length], &w, &h, &c, wantedComponents);
    AP_CHECK(bytes, return NO);
    GLenum format = (wantedComponents == 3) ? GL_RGB : GL_RGBA;

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
