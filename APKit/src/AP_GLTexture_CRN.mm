#import "AP_GLTexture_CRN.h"

#import <CoreFoundation/CoreFoundation.h>

#import <vector>

#import "AP_Check.h"

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

        void* dest = &buffer[0];
        AP_CHECK(
            crnd_unpack_level(context, &dest, total_size, row_size, i),
            break);
        
        [self compressedTexImage2dLevel:i format:format width:w height:h data:&buffer[0] dataSize:total_size];
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
