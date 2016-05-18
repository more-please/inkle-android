#ifndef MORE_C_PIXEL_FORMAT_H
#define MORE_C_PIXEL_FORMAT_H

#include <math.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum more_pixel_format_t {
    MORE_PIXEL_FORMAT_BEGIN,

    MORE_PIXEL_FORMAT_RGBA = MORE_PIXEL_FORMAT_BEGIN,
    MORE_PIXEL_FORMAT_RGB,
    MORE_PIXEL_FORMAT_RG,
    MORE_PIXEL_FORMAT_LUMINANCE_ALPHA,
    MORE_PIXEL_FORMAT_RGBA_4444,
    MORE_PIXEL_FORMAT_RGBA_5551,
    MORE_PIXEL_FORMAT_RGB_565,
    MORE_PIXEL_FORMAT_LUMINANCE,

    MORE_PIXEL_FORMAT_END,
    MORE_PIXEL_FORMAT_COUNT = MORE_PIXEL_FORMAT_END,

    MORE_PIXEL_FORMAT_UNKNOWN = -1,
} more_pixel_format_t;

//
// Human-readable name for this format (NULL on error)
//
extern const char* more_pixel_format_name(more_pixel_format_t);

//
// Parse a human-readable name into an enum (MORE_PIXEL_FORMAT_UNKNOWN on error)
//
extern more_pixel_format_t more_pixel_format_from_name(const char*);

//
// Size of pixel in bytes (returns 0 on error)
//
extern int more_pixel_format_size(more_pixel_format_t);

extern int more_pixel_format_opengl_type(more_pixel_format_t);
extern int more_pixel_format_opengl_format(more_pixel_format_t);

//
// Read a pixel from src, expand to rgba and store in dest.
// Returns a pointer to the next pixel from src.
//

extern const uint8_t* more_pixel_format_read_rgba(uint8_t dest[4], const uint8_t* src);
extern const uint8_t* more_pixel_format_read_rgb(uint8_t dest[4], const uint8_t* src);
extern const uint8_t* more_pixel_format_read_rg(uint8_t dest[4], const uint8_t* src);
extern const uint8_t* more_pixel_format_read_luminance_alpha(uint8_t dest[4], const uint8_t* src);
extern const uint8_t* more_pixel_format_read_rgba_4444(uint8_t dest[4], const uint8_t* src);
extern const uint8_t* more_pixel_format_read_rgba_5551(uint8_t dest[4], const uint8_t* src);
extern const uint8_t* more_pixel_format_read_rgb_565(uint8_t dest[4], const uint8_t* src);
extern const uint8_t* more_pixel_format_read_luminance(uint8_t dest[4], const uint8_t* src);

//
// Convert an rgba pixel from src and store it in dest.
// Returns a pointer to the next pixel in dest.
//

extern uint8_t* more_pixel_format_write_rgba(uint8_t* dest, const uint8_t src[4]);
extern uint8_t* more_pixel_format_write_rgb(uint8_t* dest, const uint8_t src[4]);
extern uint8_t* more_pixel_format_write_rg(uint8_t* dest, const uint8_t src[4]);
extern uint8_t* more_pixel_format_write_luminance_alpha(uint8_t* dest, const uint8_t src[4]);
extern uint8_t* more_pixel_format_write_rgba_4444(uint8_t* dest, const uint8_t src[4]);
extern uint8_t* more_pixel_format_write_rgba_5551(uint8_t* dest, const uint8_t src[4]);
extern uint8_t* more_pixel_format_write_rgb_565(uint8_t* dest, const uint8_t src[4]);
extern uint8_t* more_pixel_format_write_luminance(uint8_t* dest, const uint8_t src[4]);

//
// Dynamic read/write functions.
//

typedef const uint8_t* (*more_pixel_format_read_func)(uint8_t dest[4], const uint8_t* src);
typedef uint8_t* (*more_pixel_format_write_func)(uint8_t* dest, const uint8_t src[4]);

extern more_pixel_format_read_func more_pixel_format_get_read(more_pixel_format_t);
extern more_pixel_format_write_func more_pixel_format_get_write(more_pixel_format_t);

extern const uint8_t* more_pixel_format_read(
    more_pixel_format_t f, uint8_t dest[4], const uint8_t* src);

extern const uint8_t* more_pixel_format_write(
    more_pixel_format_t f, uint8_t dest[4], const uint8_t* src);

//
// Convert an entire image from one format to another.
// Pass 0 for the stride parameter(s) if the pixels are packed continuously in memory.
//
extern void more_pixel_format_convert_image(
    uint8_t* dest, more_pixel_format_t dest_format, size_t dest_stride_in_bytes,
    const uint8_t* src, more_pixel_format_t src_format, size_t src_stride_in_bytes,
    int width, int height);

#ifdef __cplusplus
} // extern "C"
#endif

// ---------------------------------------------------------------------------------------

#ifdef MORE_PIXEL_FORMAT_IMPLEMENTATION

const char* more_pixel_format_name(more_pixel_format_t f) {
    if (f < MORE_PIXEL_FORMAT_BEGIN || f >= MORE_PIXEL_FORMAT_END) {
        return NULL;
    }
    static const char* _names[MORE_PIXEL_FORMAT_COUNT] = {
        "rgba",
        "rgb",
        "rg",
        "luminance_alpha",
        "rgba_4444",
        "rgba_5551",
        "rgb_565",
        "luminance"
    };
    return _names[f];
}

more_pixel_format_t more_pixel_format_from_name(const char* name) {
    for (int i = MORE_PIXEL_FORMAT_BEGIN; i < MORE_PIXEL_FORMAT_END; ++i) {
        more_pixel_format_t format = (more_pixel_format_t) i;
        if (0 == strcasecmp(name, more_pixel_format_name(format))) {
            return format;
        }
    }
    return MORE_PIXEL_FORMAT_UNKNOWN;
}

int more_pixel_format_size(more_pixel_format_t f) {
    switch (f) {
        case MORE_PIXEL_FORMAT_RGBA:
            return 4;

        case MORE_PIXEL_FORMAT_RGB:
            return 3;

        case MORE_PIXEL_FORMAT_RG:
        case MORE_PIXEL_FORMAT_LUMINANCE_ALPHA:
        case MORE_PIXEL_FORMAT_RGBA_4444:
        case MORE_PIXEL_FORMAT_RGBA_5551:
        case MORE_PIXEL_FORMAT_RGB_565:
            return 2;

        case MORE_PIXEL_FORMAT_LUMINANCE:
            return 1;

        default:
            return 0;
    }
}

int more_pixel_format_opengl_type(more_pixel_format_t f) {
    switch (f) {
        case MORE_PIXEL_FORMAT_RGBA:
        case MORE_PIXEL_FORMAT_RGB:
        case MORE_PIXEL_FORMAT_RG:
        case MORE_PIXEL_FORMAT_LUMINANCE_ALPHA:
        case MORE_PIXEL_FORMAT_LUMINANCE:
            return 0x1401; // GL_UNSIGNED_BYTE

        case MORE_PIXEL_FORMAT_RGBA_4444:
            return 0x8033; // GL_UNSIGNED_SHORT_4_4_4_4

        case MORE_PIXEL_FORMAT_RGBA_5551:
            return 0x8034; // GL_UNSIGNED_SHORT_5_5_5_1

        case MORE_PIXEL_FORMAT_RGB_565:
            return 0x8363; // GL_UNSIGNED_SHORT_5_6_5

        default:
            return 0;
    }
}

int more_pixel_format_opengl_format(more_pixel_format_t f) {
    switch (f) {
        case MORE_PIXEL_FORMAT_RGBA:
        case MORE_PIXEL_FORMAT_RGBA_4444:
        case MORE_PIXEL_FORMAT_RGBA_5551:
            return 0x1908; // GL_RGBA

        case MORE_PIXEL_FORMAT_RGB:
        case MORE_PIXEL_FORMAT_RGB_565:
            return 0x1907; // GL_RGB

        case MORE_PIXEL_FORMAT_RG:
            return 0x8227; // GL_RG

        case MORE_PIXEL_FORMAT_LUMINANCE_ALPHA:
            return 0x190A; // GL_LUMINANCE_ALPHA

        case MORE_PIXEL_FORMAT_LUMINANCE:
            return 0x1909; // GL_LUMINANCE

        default:
            return 0;
    }
}

const uint8_t* more_pixel_format_read_rgba(uint8_t dest[4], const uint8_t* src) {
    dest[0] = *src++;
    dest[1] = *src++;
    dest[2] = *src++;
    dest[3] = *src++;
    return src;
}

const uint8_t* more_pixel_format_read_rgb(uint8_t dest[4], const uint8_t* src) {
    dest[0] = *src++;
    dest[1] = *src++;
    dest[2] = *src++;
    dest[3] = 255;
    return src;
}

const uint8_t* more_pixel_format_read_rg(uint8_t dest[4], const uint8_t* src) {
    dest[0] = *src++;
    dest[1] = *src++;
    dest[2] = 0;
    dest[3] = 255;
    return src;
}

const uint8_t* more_pixel_format_read_luminance_alpha(uint8_t dest[4], const uint8_t* src) {
    dest[0] = *src++;
    dest[1] = dest[0];
    dest[2] = dest[0];
    dest[3] = *src++;
    return src;
}

const uint8_t* more_pixel_format_read_rgba_4444(uint8_t dest[4], const uint8_t* src) {
    // Little-endian shorts
    uint8_t ba = *src++;
    uint8_t rg = *src++;
    dest[0] = 17 * ((rg >> 4) & 15);
    dest[1] = 17 * (rg & 15);
    dest[2] = 17 * ((ba >> 4) & 15);
    dest[3] = 17 * (ba & 15);
    return src;
}

const uint8_t* more_pixel_format_read_rgba_5551(uint8_t dest[4], const uint8_t* src) {
    // Little-endian shorts
    uint8_t g2b5a = *src++;
    uint8_t r5g3 = *src++;
    dest[0] = 8 * ((r5g3 >> 3) & 31);
    dest[1] = 8 * (((r5g3 & 7) << 2) | ((g2b5a >> 6) & 3));
    dest[2] = 8 * ((g2b5a >> 1) & 31);
    dest[3] = 255 * (g2b5a & 1);
    return src;
}

const uint8_t* more_pixel_format_read_rgb_565(uint8_t dest[4], const uint8_t* src) {
    // Little-endian shorts
    uint8_t g3b5 = *src++;
    uint8_t r5g3 = *src++;
    dest[0] = 8 * ((r5g3 >> 3) & 31);
    dest[1] = 4 * (((r5g3 & 7) << 3) | ((g3b5 >> 5) & 7));
    dest[2] = 8 * (g3b5 & 31);
    dest[3] = 255;
    return src;
}

const uint8_t* more_pixel_format_read_luminance(uint8_t dest[4], const uint8_t* src) {
    dest[0] = *src++;
    dest[1] = dest[0];
    dest[2] = dest[0];
    dest[3] = 255;
    return src;
}

uint8_t* more_pixel_format_write_rgba(uint8_t* dest, const uint8_t src[4]) {
    *dest++ = src[0];
    *dest++ = src[1];
    *dest++ = src[2];
    *dest++ = src[3];
    return dest;
}

uint8_t* more_pixel_format_write_rgb(uint8_t* dest, const uint8_t src[4]) {
    *dest++ = src[0];
    *dest++ = src[1];
    *dest++ = src[2];
    return dest;
}

uint8_t* more_pixel_format_write_rg(uint8_t* dest, const uint8_t src[4]) {
    *dest++ = src[0];
    *dest++ = src[1];
    return dest;
}

uint8_t* more_pixel_format_write_luminance_alpha(uint8_t* dest, const uint8_t src[4]) {
    // BT. 709 gamma-corrected luma. See https://en.wikipedia.org/wiki/Luma_(video)
    *dest++ = 0.212 * src[0] + 0.701 * src[1] + 0.087 * src[2];
    *dest++ = src[3];
    return dest;
}

uint8_t* more_pixel_format_write_rgba_4444(uint8_t* dest, const uint8_t src[4]) {
    uint8_t r4 = src[0] / 16;
    uint8_t g4 = src[1] / 16;
    uint8_t b4 = src[2] / 16;
    uint8_t a4 = src[3] / 16;
    // Little-endian shorts
    *dest++ = (b4 << 4) | a4;
    *dest++ = (r4 << 4) | g4;
    return dest;
}

uint8_t* more_pixel_format_write_rgba_5551(uint8_t* dest, const uint8_t src[4]) {
    uint8_t r5 = src[0] / 8;
    uint8_t g5 = src[1] / 8;
    uint8_t b5 = src[2] / 8;
    uint8_t a1 = src[3] / 128;
    // Little-endian shorts
    *dest++ = ((g5 & 3) << 6) | (b5 << 1) | a1;
    *dest++ = (r5 << 3) | (g5 >> 2);
    return dest;
}

uint8_t* more_pixel_format_write_rgb_565(uint8_t* dest, const uint8_t src[4]) {
    uint8_t r5 = src[0] / 8;
    uint8_t g6 = src[1] / 4;
    uint8_t b5 = src[2] / 8;
    // Little-endian shorts
    *dest++ = ((g6 & 7) << 5) | b5;
    *dest++ = (r5 << 3) | (g6 >> 3);
    return dest;
}

uint8_t* more_pixel_format_write_luminance(uint8_t* dest, const uint8_t src[4]) {
    // BT. 709 gamma-corrected luma. See https://en.wikipedia.org/wiki/Luma_(video)
    *dest++ = 0.212 * src[0] + 0.701 * src[1] + 0.087 * src[2];
    return dest;
}

more_pixel_format_read_func more_pixel_format_get_read(more_pixel_format_t f) {
    if (f < MORE_PIXEL_FORMAT_BEGIN || f >= MORE_PIXEL_FORMAT_END) {
        return NULL;
    }
    static const more_pixel_format_read_func funcs[MORE_PIXEL_FORMAT_COUNT] = {
        more_pixel_format_read_rgba,
        more_pixel_format_read_rgb,
        more_pixel_format_read_rg,
        more_pixel_format_read_luminance_alpha,
        more_pixel_format_read_rgba_4444,
        more_pixel_format_read_rgba_5551,
        more_pixel_format_read_rgb_565,
        more_pixel_format_read_luminance
    };
    return funcs[f];
}

more_pixel_format_write_func more_pixel_format_get_write(more_pixel_format_t f) {
    if (f < MORE_PIXEL_FORMAT_BEGIN || f >= MORE_PIXEL_FORMAT_END) {
        return NULL;
    }
    static const more_pixel_format_write_func funcs[MORE_PIXEL_FORMAT_COUNT] = {
        more_pixel_format_write_rgba,
        more_pixel_format_write_rgb,
        more_pixel_format_write_rg,
        more_pixel_format_write_luminance_alpha,
        more_pixel_format_write_rgba_4444,
        more_pixel_format_write_rgba_5551,
        more_pixel_format_write_rgb_565,
        more_pixel_format_write_luminance
    };
    return funcs[f];
}

const uint8_t* more_pixel_format_read(
    more_pixel_format_t f, uint8_t dest[4], const uint8_t* src)
{
    return (more_pixel_format_get_read(f))(dest, src);
}

const uint8_t* more_pixel_format_write(
    more_pixel_format_t f, uint8_t dest[4], const uint8_t* src)
{
    return (more_pixel_format_get_write(f))(dest, src);
}

void more_pixel_format_convert_image(
    uint8_t* dest, more_pixel_format_t dest_format, size_t dest_stride_in_bytes,
    const uint8_t* src, more_pixel_format_t src_format, size_t src_stride_in_bytes,
    int width, int height)
{
    if (src_stride_in_bytes == 0) {
        src_stride_in_bytes = width * more_pixel_format_size(src_format);
    }
    if (dest_stride_in_bytes == 0) {
        dest_stride_in_bytes = width * more_pixel_format_size(dest_format);
    }
    more_pixel_format_read_func read = more_pixel_format_get_read(src_format);
    more_pixel_format_write_func write = more_pixel_format_get_write(dest_format);

    for (int y = 0; y < height; ++y) {
        const uint8_t* row_src = src;
        uint8_t* row_dest = dest;
        for (int x = 0; x < width; ++x) {
            uint8_t tmp[4];
            src = read(tmp, src);
            dest = write(dest, tmp);
        }
        src = row_src + src_stride_in_bytes;
        dest = row_dest + dest_stride_in_bytes;
    }
}

#endif // MORE_PIXEL_FORMAT_IMPLEMENTATION
#endif // MORE_C_PIXEL_FORMAT_H
