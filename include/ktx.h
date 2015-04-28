#pragma once

#include <assert.h>
#include <stdint.h>
#include <stdio.h>

// Utilities for packing and unpacking KTX textures
// See http://www.khronos.org/opengles/sdk/tools/KTX/file_format_spec/

static const uint32_t KTX_ENDIANNESS = 0x04030201;

static const uint8_t KTX_MAGIC[12] = {
   0xAB, 0x4B, 0x54, 0x58, 0x20, 0x31, 0x31, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A
};

typedef struct ktx_header_t {
    uint8_t magic[12];
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
} ktx_header_t;

typedef enum ktx_pixel_type_t {
    KTX_TYPE_NONE = 0,

    KTX_UNSIGNED_BYTE = 0x1401,
    KTX_UNSIGNED_SHORT_4_4_4_4 = 0x8033,
    KTX_UNSIGNED_SHORT_5_5_5_1 = 0x8034,
    KTX_UNSIGNED_SHORT_5_6_5 = 0x8363
} ktx_pixel_type_t;

typedef enum ktx_pixel_format_t {
    KTX_FORMAT_NONE = 0,

    KTX_ALPHA = 0x1906,
    KTX_RGB = 0x1907,
    KTX_RGBA = 0x1908,
    KTX_LUMINANCE = 0x1909,
    KTX_LUMINANCE_ALPHA = 0x190A
} ktx_pixel_format_t;

// Write a single texture to a KTX file.
// Returns 0 on failures and non-zero on success.
int ktx_write_2d_uncompressed(
    FILE* f,
    uint32_t glType, // e.g. GL_UNSIGNED_BYTE, GL_UNSIGNED_SHORT_5_6_5
    uint32_t glFormat, // e.g. GL_RGB, GL_RGBA
    uint32_t width,
    uint32_t height,
    const uint8_t* data,
    uint32_t data_length)
{
    const ktx_pixel_type_t type = (ktx_pixel_type_t) glType;
    const ktx_pixel_format_t format = (ktx_pixel_format_t) glFormat;

    ktx_header_t header;
    memset(&header, 0, sizeof(header));

    memcpy(header.magic, KTX_MAGIC, sizeof(header.magic));
    header.endianness = KTX_ENDIANNESS;
    header.glType = type;
    header.glFormat = format;

    // See ES 2.0 spec, table 3.4
    const struct {
        ktx_pixel_format_t glFormat;
        ktx_pixel_type_t glType;
        uint32_t glTypeSize;
    } TYPE_SIZE[] = {
        { KTX_RGBA, KTX_UNSIGNED_BYTE, 4 },
        { KTX_RGB, KTX_UNSIGNED_BYTE, 3 },
        { KTX_RGBA, KTX_UNSIGNED_SHORT_4_4_4_4, 2 },
        { KTX_RGBA, KTX_UNSIGNED_SHORT_5_5_5_1, 2 },
        { KTX_RGB, KTX_UNSIGNED_SHORT_5_6_5, 2 },
        { KTX_LUMINANCE_ALPHA, KTX_UNSIGNED_BYTE, 2 },
        { KTX_LUMINANCE, KTX_UNSIGNED_BYTE, 1 },
        { KTX_ALPHA, KTX_UNSIGNED_BYTE, 1 },
        { KTX_FORMAT_NONE, KTX_TYPE_NONE, 0 }
    };

    for (int i = 0; TYPE_SIZE[i].glTypeSize; ++i) {
        if (TYPE_SIZE[i].glFormat == glFormat && TYPE_SIZE[i].glType == glType) {
            header.glTypeSize = TYPE_SIZE[i].glTypeSize;
            break;
        }
    }
    if (!header.glTypeSize) {
        fprintf(stderr, "Illegal KTX type/format combination: %x / %x\n", glType, glFormat);
        return 0;
    }

    if (data_length != width * height * header.glTypeSize) {
        fprintf(stderr, "KTX data_length was %d, expected %d\n", data_length, width * height * header.glTypeSize);
        return 0;
    }

    header.glInternalFormat = glFormat; // Only used for compressed textures
    header.glBaseInternalFormat = glFormat; // Only used for compressed textures
    header.pixelWidth = width;
    header.pixelHeight = height;
    header.pixelDepth = 0; // Only used for 3D textures
    header.numberOfArrayElements = 0; // Only used for texture arrays
    header.numberOfFaces = 1; // Only used for cubemaps
    header.numberOfMipmapLevels = 0; // Request glGenerateMipmap at runtime
    header.bytesOfKeyValueData = 0;

    fwrite((const void*) &header, 1, sizeof(header), f);
    fwrite((const void*) &data_length, 1, sizeof(data_length), f);
    fwrite((const void*) data, data_length, 1, f);
    for (uint32_t i = data_length; i & 3; ++i) {
        putc(0, f);
    }
    fflush(f);
    return 1;
}
