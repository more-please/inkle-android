#include <stdio.h>

#define MORE_PLEASE_IMPLEMENTATION
#include "more-c/please.h"
#include "more-cpp/please.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb/stb_image.h"

#define STB_DXT_IMPLEMENTATION
#include "stb/stb_dxt.h"

#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
#endif

#define STB_IMAGE_RESIZE_IMPLEMENTATION
#include "stb/stb_image_resize.h"

#ifdef __clang__
#pragma clang diagnostic pop
#endif

using namespace more::please;

typedef void (*compression_func)(uint8_t* dest, const uint8_t* src, int w, int h);

static void compress_dxt1(uint8_t* dest, const uint8_t* src, int w, int h);
static void compress_dxt5(uint8_t* dest, const uint8_t* src, int w, int h);

static struct {
    more_ktx_compressed_t compression;
    const char* name;
    compression_func func;
} COMPRESSION[] = {
    { MORE_KTX_COMPRESSED_RGB_DXT1, "dxt1", compress_dxt1 },
    { MORE_KTX_COMPRESSED_RGBA_DXT5, "dxt5", compress_dxt5 },
    { MORE_KTX_COMPRESSED_NONE, NULL, NULL }
};

void print_format_list(FILE* f) {
    fprintf(f, "Uncompressed formats:\n");
    for (int i = MORE_PIXEL_FORMAT_BEGIN; i < MORE_PIXEL_FORMAT_END; ++i) {
        fprintf(f, "\t%s\n", more_pixel_format_name((more_pixel_format_t) i));
    }
    fprintf(f, "\nCompressed formats:\n");
    for (int i = 0; COMPRESSION[i].name; ++i) {
        fprintf(f, "\t%s\n", COMPRESSION[i].name);
    }
    fprintf(f, "\n");
}

cstr_flag infile("in", "Input image (.png or .jpeg)");
cstr_flag outfile("out", "Output file (.ktx)");
bool_flag mipmaps("mipmaps", "If set, generate mipmaps");
bool_flag wrap("wrap", "If set, image wraps in both directions");
bool_flag linear("linear", "If set, use linear colorspace (default: sRGB)");

int make_ktx(more_pixel_format_t pixel_format) {
    vlog("Loading %s", (const char*) infile);

    int w, h, comp;
    uint8_t* src = stbi_load(infile, &w, &h, &comp, 4);
    if (!src) {
        error("Failed to open input file: %s", (const char*) infile);
    }

    more_ktx_type_t ktx_type = (more_ktx_type_t) more_pixel_format_opengl_type(pixel_format);
    more_ktx_format_t ktx_format = (more_ktx_format_t) more_pixel_format_opengl_format(pixel_format);

    size_t ktx_size;
    uint8_t* ktx = more_ktx_alloc(
        ktx_type, ktx_format, w, h,
        mipmaps ? MORE_KTX_FLAG_MIPMAPS : 0,
        &ktx_size);
    if (!ktx) {
        error("Failed to build KTX file");
    }

    uint8_t* buffer = (uint8_t*) malloc(w * h * 4);

    int num_levels = more_ktx_get_num_mipmaps(ktx);
    for (int level = 0; level < num_levels; ++level) {
        vlog("Building mipmap %d", level);

        uint32_t w2, h2, size;
        uint8_t* dest = more_ktx_get_mipmap(ktx, level, &w2, &h2, &size);
        if (!dest) {
            error("Failed to access mipmap level %d (of %d)", level, num_levels);
        }

        // Resize src -> buffer
        int success = stbir_resize_uint8_generic(
            src, w, h, 0,
            buffer, w2, h2, 0,
            4, // num_channels
            3, // alpha_channel
            0, // flags
            wrap ? STBIR_EDGE_WRAP : STBIR_EDGE_CLAMP,
            STBIR_FILTER_BOX,
            linear ? STBIR_COLORSPACE_LINEAR : STBIR_COLORSPACE_SRGB,
            NULL);
        if (!success) {
            error("stbir_resize_uint8_generic failed");
        }

        // Swap src <-> buffer
        uint8_t* tmp = src;
        src = buffer;
        buffer = tmp;
        w = w2, h = h2;

        // Copy and convert input into the KTX mipmap.
        more_pixel_format_convert_image(
            dest, pixel_format, 0,
            src, MORE_PIXEL_FORMAT_RGBA, 0,
            w, h);
    }

    free(buffer);
    free(src);

    vlog("Writing %s", (const char*) outfile);
    if (!more_file_write(outfile, ktx, ktx_size)) {
        error("Failed to write output file: %s", (const char*) outfile);
    }

    free(ktx);
    return 0;
}

static int min(int a, int b) {
    return (a > b) ? b : a;
}

static void extract_dxt_block(uint8_t dest[64], const uint8_t* src, int w, int h, int x, int y) {
    int stride = w * 4;
    for (int dy = 0; dy < 4; ++dy) {
        for (int dx = 0; dx < 4; ++dx) {
            for (int c = 0; c < 4; ++c) {
                dest[16 * dy + 4*dx + c] = src[stride * min(h - 1, y + dy) + 4 * min(w - 1, x + dx) + c];
            }
        }
    }
}

static void compress_dxt1(uint8_t* dest, const uint8_t* src, int w, int h) {
    uint8_t block[64];
    for (int y = 0; y < h; y += 4) {
        for (int x = 0; x < w; x += 4) {
            extract_dxt_block(block, src, w, h, x, y);
            stb_compress_dxt_block(dest, block, 0, STB_DXT_HIGHQUAL);
            dest += 8;
        }
    }
}

static void compress_dxt5(uint8_t* dest, const uint8_t* src, int w, int h) {
    uint8_t block[64];
    for (int y = 0; y < h; y += 4) {
        for (int x = 0; x < w; x += 4) {
            extract_dxt_block(block, src, w, h, x, y);
            stb_compress_dxt_block(dest, block, 1, STB_DXT_HIGHQUAL);
            dest += 16;
        }
    }
}

int make_ktx_compressed(more_ktx_compressed_t compression, compression_func compress) {
    vlog("Loading %s", (const char*) infile);

    int w, h, comp;
    uint8_t* src = stbi_load(infile, &w, &h, &comp, 4);
    if (!src) {
        error("Failed to open input file: %s", (const char*) infile);
    }

    size_t ktx_size;
    uint8_t* ktx = more_ktx_alloc_compressed(
        compression, w, h,
        mipmaps ? MORE_KTX_FLAG_MIPMAPS : 0,
        &ktx_size);
    if (!ktx) {
        error("Failed to build KTX file");
    }

    uint8_t* buffer = (uint8_t*) malloc(w * h * 4);

    int num_levels = more_ktx_get_num_mipmaps(ktx);
    for (int level = 0; level < num_levels; ++level) {
        vlog("Building mipmap %d", level);

        uint32_t w2, h2, size;
        uint8_t* dest = more_ktx_get_mipmap(ktx, level, &w2, &h2, &size);
        if (!dest) {
            error("Failed to access mipmap level %d (of %d)", level, num_levels);
        }

        // Resize src -> buffer
        int success = stbir_resize_uint8_generic(
            src, w, h, 0,
            buffer, w2, h2, 0,
            4, // num_channels
            3, // alpha_channel
            0, // flags
            wrap ? STBIR_EDGE_WRAP : STBIR_EDGE_CLAMP,
            STBIR_FILTER_BOX,
            linear ? STBIR_COLORSPACE_LINEAR : STBIR_COLORSPACE_SRGB,
            NULL);
        if (!success) {
            error("stbir_resize_uint8_generic failed");
        }

        // Swap src <-> buffer
        uint8_t* tmp = src;
        src = buffer;
        buffer = tmp;
        w = w2, h = h2;

        // Copy and compress input into the KTX mipmap.
        compress(dest, src, w, h);
    }

    free(buffer);
    free(src);

    vlog("Writing %s", (const char*) outfile);
    if (!more_file_write(outfile, ktx, ktx_size)) {
        error("Failed to write output file: %s", (const char*) outfile);
    }

    free(ktx);
    return 0;
}

int main(int argc, const char* argv[]) {

    class list_flag : base_flag {
    public:
        list_flag() : base_flag("list", "List the available texture formats") {}

        int handle(int argc, const char* argv[]) {
            print_format_list(stdout);
            exit(0);
            return 1;
        }
    } list;

    cstr_flag format_name("format", "Texture format");

    parse_args(argc, argv);

    more_pixel_format_t pixel_format = more_pixel_format_from_name(format_name);
    if (pixel_format != MORE_PIXEL_FORMAT_UNKNOWN) {
        return make_ktx(pixel_format);
    }

    for (int i = 0; COMPRESSION[i].name; ++i) {
        if (0 == strcasecmp(format_name, COMPRESSION[i].name)) {
            return make_ktx_compressed(COMPRESSION[i].compression, COMPRESSION[i].func);
        }
    }

    error("Unknown format: %s", (const char*) format_name);
    return 1;
}
