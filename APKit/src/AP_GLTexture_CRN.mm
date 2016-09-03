#import "AP_GLTexture_CRN.h"

#ifdef SORCERY_SDL

#import <CoreFoundation/CoreFoundation.h>

#import <vector>

#import "AP_Check.h"
#import "AP_Window.h"

#undef _MSC_VER
#undef check
#define malloc_usable_size malloc_size

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#import "crn_decomp.h"

#pragma clang diagnostic pop

#define GL_COMPRESSED_RGB_S3TC_DXT1_EXT                         0x83F0
#define GL_COMPRESSED_RGBA_S3TC_DXT1_EXT                        0x83F1
#define GL_COMPRESSED_RGBA_S3TC_DXT3_EXT                        0x83F2
#define GL_COMPRESSED_RGBA_S3TC_DXT5_EXT                        0x83F3

using namespace crnd;

@implementation AP_GLTexture (CRN)

+ (BOOL) isCRN:(NSData *)data
{
    crn_texture_info info;
    return crnd_get_texture_info(data.bytes, data.length, &info);
}

- (BOOL) loadCRN:(NSData*)data
{
    static GLint systemMaxTextureSize = 0;
    static GLint systemMaxCubeTextureSize = 0;
    if (systemMaxTextureSize == 0) {
        _GL(GetIntegerv, GL_MAX_TEXTURE_SIZE, &systemMaxTextureSize);
        _GL(GetIntegerv, GL_MAX_CUBE_MAP_TEXTURE_SIZE, &systemMaxCubeTextureSize);
    }
    if (systemMaxTextureSize == 0) {
        NSLog(@"*** glGetIntegerv(GL_MAX_TEXTURE_SIZE) returned 0 -- weird!");
        systemMaxTextureSize = 2048; // Should be safe
        systemMaxCubeTextureSize = 2048;
    }
    GLint maxSize = self.cube ? systemMaxCubeTextureSize : systemMaxTextureSize;

    BOOL crappy = [UIApplication sharedApplication].isCrappyDevice;
    if (crappy && maxSize > 2048) {
        maxSize = 2048;
    }

    crn_texture_info info;
    AP_CHECK(crnd_get_texture_info(data.bytes, data.length, &info), return NO);

    NSLog(@"Loading CRN: size %dx%d, format %d, mipmaps %d",
        info.m_width, info.m_height, (int) info.m_format, info.m_levels);

    GLenum format;
    switch (info.m_format) {
        case cCRNFmtDXT1:
            format = GL_COMPRESSED_RGB_S3TC_DXT1_EXT;
            break;
        case cCRNFmtDXT3:
            format = GL_COMPRESSED_RGBA_S3TC_DXT3_EXT;
            break;
        case cCRNFmtDXT5:
            format = GL_COMPRESSED_RGBA_S3TC_DXT5_EXT;
            break;
        default:
            NSLog(@"Unsupported CRN format: %d", (int) info.m_format);
            return NO;
    }

    const int w = (info.m_width + 3) & ~3;
    const int h = (info.m_height + 3) & ~3;
    const int stride = (w * crnd_get_crn_format_bits_per_texel(info.m_format)) / 8;

    std::vector<char> buffer (h * stride);

    crnd_unpack_context context = crnd_unpack_begin(data.bytes, data.length);
    AP_CHECK(context, return NO);

    int skipped = 0;
    for (int i = 0; i < info.m_levels; ++i) {
        crn_level_info level;
        AP_CHECK(
            crnd_get_level_info(data.bytes, data.length, i, &level),
            break);

        const int w = level.m_width;
        const int h = level.m_height;
        const int blocks_x = (w + 3) / 4;
        const int blocks_y = (h + 3) / 4;
        const int block_size = 2 * crnd_get_crn_format_bits_per_texel(info.m_format);
        const int row_size = blocks_x * block_size;
        const int total_size = blocks_y * row_size;

        if (i+1 < info.m_levels) {
            // This isn't the last mipmap, maybe skip it
            if (crappy && i == 0 && (w > 128 || h > 128)) {
                NSLog(@"Skipping mipmap level %d (low-end GPU)", i);
                ++skipped;
                continue;
            }
            if (w > maxSize || h > maxSize) {
                NSLog(@"Skipping mipmap level %d (width %d, height %d, max %d)", i, w, h, maxSize);
                ++skipped;
                continue;
            }
        }

        void* dest = &buffer[0];
        AP_CHECK(
            crnd_unpack_level(context, &dest, total_size, row_size, i),
            break);
        [self compressedTexImage2dLevel:i - skipped format:format width:w height:h data:&buffer[0] dataSize:total_size];
    }

    crnd_unpack_end(context);

    _GL(TexParameteri, self.textureTarget, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    if (info.m_levels > 1) {
        _GL(TexParameteri, self.textureTarget, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    } else {
        _GL(TexParameteri, self.textureTarget, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    }

    return YES;
}

@end

#endif // SORCERY_SDL
