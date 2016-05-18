// Functions for reading and writing KTX files.
// See http://www.khronos.org/opengles/sdk/tools/KTX/file_format_spec/

#ifndef MORE_C_KTX_H
#define MORE_C_KTX_H

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

extern int more_ktx_is_valid(const uint8_t* ptr, size_t size);

extern int more_ktx_is_compressed(const uint8_t* ktx);

extern uint32_t more_ktx_get_num_mipmaps(const uint8_t* ktx);

extern uint8_t* more_ktx_get_mipmap(
    uint8_t* ktx,
    uint32_t level,
    uint32_t* out_width,
    uint32_t* out_height,
    uint32_t* out_size);

extern const uint8_t* more_ktx_get_mipmap_const(
    const uint8_t* ktx,
    uint32_t level,
    uint32_t* out_width,
    uint32_t* out_height,
    uint32_t* out_size);


typedef enum more_ktx_type_t {
    MORE_KTX_TYPE_NONE = 0,

    MORE_KTX_UNSIGNED_BYTE = 0x1401,
    MORE_KTX_UNSIGNED_SHORT_4_4_4_4 = 0x8033,
    MORE_KTX_UNSIGNED_SHORT_5_5_5_1 = 0x8034,
    MORE_KTX_UNSIGNED_SHORT_5_6_5 = 0x8363
} more_ktx_type_t;

typedef enum more_ktx_format_t {
    MORE_KTX_FORMAT_NONE = 0,

    MORE_KTX_ALPHA = 0x1906,
    MORE_KTX_RGB = 0x1907,
    MORE_KTX_RGBA = 0x1908,
    MORE_KTX_LUMINANCE = 0x1909,
    MORE_KTX_LUMINANCE_ALPHA = 0x190A
} more_ktx_format_t;

enum {
    MORE_KTX_FLAG_NONE = 0,

    MORE_KTX_FLAG_MIPMAPS = 1,
};

//
// Create a KTX data structure for holding uncompressed textures.
// Returns a malloc'd pointer (or NULL on error). The caller must free() it.
// All mipmaps are initialized to 0, and must be filled in by the caller.
// To get a pointer to each mipmap buffer, call more_ktx_get_mipmap().
//
extern uint8_t* more_ktx_alloc(
    more_ktx_type_t type,
    more_ktx_format_t format,
    uint32_t width,
    uint32_t height,
    int flags,
    size_t* out_size);


typedef enum more_ktx_compressed_t {
    MORE_KTX_COMPRESSED_NONE = 0,

    MORE_KTX_COMPRESSED_RGB_DXT1 = 0x83F0,
    MORE_KTX_COMPRESSED_RGBA_DXT1 = 0x83F1,
    MORE_KTX_COMPRESSED_RGBA_DXT3 = 0x83F2,
    MORE_KTX_COMPRESSED_RGBA_DXT5 = 0x83F3
} more_ktx_compressed_t;

//
// As above, for compressed textures.
//
extern uint8_t* more_ktx_alloc_compressed(
    more_ktx_compressed_t compression,
    uint32_t width,
    uint32_t height,
    int flags,
    size_t* out_size);

#ifdef __cplusplus
} // extern "C"
#endif

// ---------------------------------------------------------------------------------------

#ifdef MORE_KTX_IMPLEMENTATION

#define MORE_KTX_MAGIC_SIZE 12
#define MORE_KTX_MAGIC "\xABKTX 11\xBB\r\n\x1A\n"
#define MORE_KTX_ENDIANNESS 0x04030201

typedef struct more_ktx_header_t {
    uint8_t magic[MORE_KTX_MAGIC_SIZE];
    uint32_t endianness;
    uint32_t glType;
    uint32_t glTypeSize;
    uint32_t glFormat;
    uint32_t glInternalFormat;
    uint32_t glBaseInternalFormat;
    uint32_t pixelWidth;
    uint32_t pixelHeight;
    uint32_t pixelDepth;
    uint32_t numberOfArrayElements;
    uint32_t numberOfFaces;
    uint32_t numberOfMipmapLevels;
    uint32_t bytesOfKeyValueData;
} more_ktx_header_t;

static uint32_t more_ktx_noop32(uint32_t n) {
    return n;
}

static uint32_t more_ktx_swap32(uint32_t n) {
    return (n & 0x000000ff) << 24
        | (n & 0x0000ff00) << 8
        | (n & 0x00ff0000) >> 8
        | (n & 0xff000000) >> 24;
}

typedef uint32_t (*more_ktx_get32)(uint32_t);

static more_ktx_get32 more_ktx_get32_func(uint32_t endianness) {
    if (endianness == MORE_KTX_ENDIANNESS) {
        return more_ktx_noop32;
    } else if (endianness == more_ktx_swap32(MORE_KTX_ENDIANNESS)) {
        return more_ktx_swap32;
    } else {
        return NULL;
    }
}

static uint32_t more_ktx_div2(uint32_t n) {
    return (n > 1) ? (n / 2) : 1;
}

static uint32_t more_ktx_pad4(uint32_t n) {
    return (n + 3) & ~3;
}

static uint32_t more_ktx_pixel_size(
    more_ktx_type_t type,
    more_ktx_format_t format)
{
    static const struct {
        more_ktx_format_t format;
        more_ktx_type_t type;
        uint32_t size;
    } TYPE_SIZE[] = {
        { MORE_KTX_RGBA,            MORE_KTX_UNSIGNED_BYTE,             4 },
        { MORE_KTX_RGB,             MORE_KTX_UNSIGNED_BYTE,             3 },
        { MORE_KTX_RGBA,            MORE_KTX_UNSIGNED_SHORT_4_4_4_4,    2 },
        { MORE_KTX_RGBA,            MORE_KTX_UNSIGNED_SHORT_5_5_5_1,    2 },
        { MORE_KTX_RGB,             MORE_KTX_UNSIGNED_SHORT_5_6_5,      2 },
        { MORE_KTX_LUMINANCE_ALPHA, MORE_KTX_UNSIGNED_BYTE,             2 },
        { MORE_KTX_LUMINANCE,       MORE_KTX_UNSIGNED_BYTE,             1 },
        { MORE_KTX_ALPHA,           MORE_KTX_UNSIGNED_BYTE,             1 },
        { MORE_KTX_FORMAT_NONE,     MORE_KTX_TYPE_NONE,                 0 }
    };

    for (int i = 0; TYPE_SIZE[i].size; ++i) {
        if (TYPE_SIZE[i].format == format && TYPE_SIZE[i].type == type) {
            return TYPE_SIZE[i].size;
        }
    }
    return 0;
}

int more_ktx_is_valid(const uint8_t* ptr, size_t size) {
    if (size < sizeof(more_ktx_header_t)) {
        return 0;
    }

    more_ktx_header_t* h = (more_ktx_header_t*) ptr;
    if (memcmp(h->magic, MORE_KTX_MAGIC, MORE_KTX_MAGIC_SIZE)) {
        return 0;
    }

    more_ktx_get32 get32 = more_ktx_get32_func(h->endianness);
    int numMipmaps = get32(h->numberOfMipmapLevels);
    if (numMipmaps == 0) {
        numMipmaps = 1;
    }

    const uint8_t* maxPtr = ptr + size;
    ptr += sizeof(more_ktx_header_t);
    ptr += get32(h->bytesOfKeyValueData);

    for (int i = 0; i < numMipmaps; ++i) {
        if (ptr + 4 > maxPtr) {
            return 0;
        }
        uint32_t mipmap_size = get32(*(const uint32_t*) ptr);
        ptr += 4 + more_ktx_pad4(mipmap_size);
    }

    if (ptr > maxPtr) {
        return 0;
    }

    return 1;
}

int more_ktx_is_compressed(const uint8_t* ktx) {
    more_ktx_header_t* h = (more_ktx_header_t*) ktx;
    more_ktx_get32 get32 = more_ktx_get32_func(h->endianness);
    return get32(h->glType) == 0;
}

uint8_t* more_ktx_alloc(
    more_ktx_type_t type,
    more_ktx_format_t format,
    uint32_t width,
    uint32_t height,
    int flags,
    size_t* out_size)
{
    if (out_size) {
        *out_size = 0;
    }

    int num_mipmaps = 1;
    if (flags & MORE_KTX_FLAG_MIPMAPS) {
        int w = width, h = height;
        while (w > 1 || h > 1) {
            w = more_ktx_div2(w);
            h = more_ktx_div2(h);
            ++num_mipmaps;
        }
    }

    uint32_t pixel_size = more_ktx_pixel_size(type, format);
    if (!pixel_size) {
        return NULL;
    }

    uint32_t total_image_size = 0;
    int w = width, h = height;
    for (int i = 0; i < num_mipmaps; ++i) {
        total_image_size += 4 + more_ktx_pad4(w * h * pixel_size);
        w = more_ktx_div2(w);
        h = more_ktx_div2(h);
    }

    uint32_t total_size = sizeof(more_ktx_header_t) + total_image_size;
    more_ktx_header_t* result = (more_ktx_header_t*) calloc(total_size, 1);
    if (!result) {
        return NULL;
    }

    memcpy(result->magic, MORE_KTX_MAGIC, MORE_KTX_MAGIC_SIZE);
    result->endianness = MORE_KTX_ENDIANNESS;
    result->glType = type;
    result->glFormat = format;
    result->glInternalFormat = format;
    result->glBaseInternalFormat = format;
    result->pixelWidth = width;
    result->pixelHeight = height;
    result->pixelDepth = 0; // TODO: support 3D textures?
    result->numberOfArrayElements = 0; // TODO: support array textures?
    result->numberOfFaces = 1; // TODO: support cube maps?
    result->numberOfMipmapLevels = num_mipmaps;
    result->bytesOfKeyValueData = 0; // TODO: support tags?

    uint8_t* ptr = (uint8_t*) (result + 1);
    w = width, h = height;
    for (int i = 0; i < num_mipmaps; ++i) {
        uint32_t mipmap_size = w * h * pixel_size;
        w = more_ktx_div2(w);
        h = more_ktx_div2(h);

        (*(uint32_t*) ptr) = mipmap_size;
        ptr += 4 + more_ktx_pad4(mipmap_size);
    }

    if (out_size) {
        *out_size = total_size;
    }
    return (uint8_t*) result;
}

static uint32_t more_ktx_bits_per_pixel(more_ktx_compressed_t c) {
    switch (c) {
        case MORE_KTX_COMPRESSED_RGB_DXT1:
        case MORE_KTX_COMPRESSED_RGBA_DXT1:
            return 4;

        case MORE_KTX_COMPRESSED_RGBA_DXT3:
        case MORE_KTX_COMPRESSED_RGBA_DXT5:
            return 8;

        default:
            return 0;
    }
}

static more_ktx_format_t more_ktx_internal_format(more_ktx_compressed_t c) {
    switch (c) {
        case MORE_KTX_COMPRESSED_RGB_DXT1:
            return MORE_KTX_RGB;

        case MORE_KTX_COMPRESSED_RGBA_DXT1:
        case MORE_KTX_COMPRESSED_RGBA_DXT3:
        case MORE_KTX_COMPRESSED_RGBA_DXT5:
            return MORE_KTX_RGBA;

        default:
            return MORE_KTX_FORMAT_NONE;
    }
}

uint8_t* more_ktx_alloc_compressed(
    more_ktx_compressed_t compression,
    uint32_t width,
    uint32_t height,
    int flags,
    size_t* out_size)
{
    if (out_size) {
        *out_size = 0;
    }

    int num_mipmaps = 1;
    if (flags & MORE_KTX_FLAG_MIPMAPS) {
        int w = width, h = height;
        while (w > 1 || h > 1) {
            w = more_ktx_div2(w);
            h = more_ktx_div2(h);
            ++num_mipmaps;
        }
    }

    uint32_t bpp = more_ktx_bits_per_pixel(compression);
    if (!bpp) {
        return NULL;
    }

    uint32_t total_image_size = 0;
    int w = width, h = height;
    for (int i = 0; i < num_mipmaps; ++i) {
        total_image_size += 4 + (more_ktx_pad4(w) * more_ktx_pad4(h) * bpp) / 8;
        w = more_ktx_div2(w);
        h = more_ktx_div2(h);
    }

    uint32_t total_size = sizeof(more_ktx_header_t) + total_image_size;
    more_ktx_header_t* result = (more_ktx_header_t*) calloc(total_size, 1);
    if (!result) {
        return NULL;
    }

    memcpy(result->magic, MORE_KTX_MAGIC, MORE_KTX_MAGIC_SIZE);
    result->endianness = MORE_KTX_ENDIANNESS;
    result->glType = 0;
    result->glFormat = 0;
    result->glInternalFormat = compression;
    result->glBaseInternalFormat = more_ktx_internal_format(compression);
    result->pixelWidth = width;
    result->pixelHeight = height;
    result->pixelDepth = 0; // TODO: support 3D textures?
    result->numberOfArrayElements = 0; // TODO: support array textures?
    result->numberOfFaces = 1; // TODO: support cube maps?
    result->numberOfMipmapLevels = num_mipmaps;
    result->bytesOfKeyValueData = 0; // TODO: support tags?

    uint8_t* ptr = (uint8_t*) (result + 1);
    w = width, h = height;
    for (int i = 0; i < num_mipmaps; ++i) {
        uint32_t mipmap_size = (more_ktx_pad4(w) * more_ktx_pad4(h) * bpp) / 8;
        w = more_ktx_div2(w);
        h = more_ktx_div2(h);

        (*(uint32_t*) ptr) = mipmap_size;
        ptr += 4 + more_ktx_pad4(mipmap_size);
    }

    if (out_size) {
        *out_size = total_size;
    }
    return (uint8_t*) result;
}

uint32_t more_ktx_get_num_mipmaps(const uint8_t* ktx) {
    const more_ktx_header_t* header = (const more_ktx_header_t*) ktx;
    more_ktx_get32 get32 = more_ktx_get32_func(header->endianness);
    return get32(header->numberOfMipmapLevels);
}

uint8_t* more_ktx_get_mipmap(
    uint8_t* ktx,
    uint32_t level,
    uint32_t* out_width,
    uint32_t* out_height,
    uint32_t* out_size)
{
    if (out_width) *out_width = 0;
    if (out_height) *out_height = 0;
    if (out_size) *out_size = 0;

    more_ktx_header_t* header = (more_ktx_header_t*) ktx;
    more_ktx_get32 get32 = more_ktx_get32_func(header->endianness);
    uint32_t num_mipmaps = get32(header->numberOfMipmapLevels);
    if (num_mipmaps == 0) {
        num_mipmaps = 1;
    }
    if (level >= num_mipmaps) {
        return NULL;
    }

    uint32_t w = get32(header->pixelWidth);
    uint32_t h = get32(header->pixelHeight);
    
    uint8_t* ptr = ktx + sizeof(more_ktx_header_t);
    ptr += get32(header->bytesOfKeyValueData);

    for (int i = 0; i < num_mipmaps; ++i) {
        uint32_t size = get32(*(uint32_t*)ptr);
        ptr += 4;

        if (i == level) {
            if (out_width) *out_width = w;
            if (out_height) *out_height = h;
            if (out_size) *out_size = size;
            return ptr;
        }

        w = more_ktx_div2(w);
        h = more_ktx_div2(h);
        ptr += more_ktx_pad4(size);
    }

    return NULL;
}

const uint8_t* more_ktx_get_mipmap_const(
    const uint8_t* ktx,
    uint32_t level,
    uint32_t* out_width,
    uint32_t* out_height,
    uint32_t* out_size)
{
    return more_ktx_get_mipmap((uint8_t*) ktx, level, out_width, out_height, out_size);
}

#endif // MORE_KTX_IMPLEMENTATION
#endif // MORE_C_KTX_H
