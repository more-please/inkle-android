#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ktx.h"
#include "rgba.h"

#include "read_entire_file.h"
#include "stb_image.h"
#include "stb_image_resize.h"
#include "sharpen.h"

void usage() {
    fprintf(stderr,
        "Convert an image into an uncompressed texture in KTX format.\n\n"
        "Usage: ktx [-f RGBA|RGB|LA|L|A] [-t 8|4444|5551|565] [-i in.png] [-o out.ktx]\n\n"
        "  -f, --format: output format (default is RGBA)\n"
        "  -t, --type: storage type (default is 8, i.e. UNSIGNED_BYTE)\n"
        "  -m, --mipmaps: generate mipmaps\n"
        "  -s, --sharpen: sharpen the image\n"
        "  -i, --infile: input file (default is stdin)\n"
        "  -o, --outfile: output file (default is stdout)\n");
    fflush(stderr);
    exit(1);
}

bool isFlag(const char* s, const char* flag1, const char* flag2) {
    return strcmp(s, flag1) == 0 || strcmp(s, flag2) == 0;
}

int main(int argc, const char* argv[]) {
    const char* infile = NULL;
    FILE* outfile = stdout;

    ktx_pixel_format_t format = KTX_RGBA;
    ktx_pixel_type_t type = KTX_UNSIGNED_BYTE;
    bool mipmaps = false;
    bool sharp = false;

    for (int i = 1; i < argc; ++i) {
        const char* s = argv[i];
        if (isFlag(s, "-i", "--infile")) {
            infile = argv[++i];
        } else if (isFlag(s, "-o", "--outfile")) {
            outfile = fopen(argv[++i], "wb");
        } else if (isFlag(s, "-f", "--format")) {
            s = argv[++i];
            if (strcasecmp(s, "RGBA") == 0) {
                format = KTX_RGBA;
            } else if (strcasecmp(s, "RGB") == 0) {
                format = KTX_RGB;
            } else if (strcasecmp(s, "LA") == 0) {
                format = KTX_LUMINANCE_ALPHA;
            } else if (strcasecmp(s, "L") == 0) {
                format = KTX_LUMINANCE;
            } else if (strcasecmp(s, "A") == 0) {
                format = KTX_ALPHA;
            } else {
                fprintf(stderr, "Unsupported format: %s\n\n", s);
                usage();
            }
        } else if (isFlag(s, "-t", "--type")) {
            s = argv[++i];
            if (strcasecmp(s, "8") == 0) {
                type = KTX_UNSIGNED_BYTE;
            } else if (strcasecmp(s, "4444") == 0) {
                type = KTX_UNSIGNED_SHORT_4_4_4_4;
            } else if (strcasecmp(s, "5551") == 0) {
                type = KTX_UNSIGNED_SHORT_5_5_5_1;
            } else if (strcasecmp(s, "565") == 0) {
                type = KTX_UNSIGNED_SHORT_5_6_5;
            } else {
                fprintf(stderr, "Unsupported type: %s\n\n", s);
                usage();
            }
        } else if (isFlag(s, "-m", "--mipmaps")) {
            mipmaps = true;
        } else if (isFlag(s, "-s", "--sharpen")) {
            sharp = true;
        } else {
            fprintf(stderr, "Bad argument '%s'\n\n", s);
            usage();
        }
    }

    std::vector<unsigned char> file = read_entire_file(infile);

    int w, h, comp;
    unsigned char* rgba8 = stbi_load_from_memory(&file[0], file.size(), &w, &h, &comp, 4);

    float* f_rgba = (float*) malloc(w * h * 4 * sizeof(float));
    for (int i = 0; i < (w * h * 4); ++i) {
        f_rgba[i] = rgba8[i];
    }
    stbi_image_free(rgba8);

    int numMipmaps = 0;
    if (mipmaps) {
        ++numMipmaps;
        int w2 = w, h2 = h;
        while (w2 > 1 || h2 > 1) {
            ++numMipmaps;
            w2 = (w2 > 1) ? (w2 / 2) : 1;
            h2 = (h2 > 1) ? (h2 / 2) : 1;
        }
    }

    int success = ktx_write_header(outfile, type, format, w, h, mipmaps ? numMipmaps : 0);
    if (!success) {
        fprintf(stderr, "Failed to write KTX header\n");
        return -1;
    }

    unsigned char* output = (unsigned char*) malloc(w * h * 4);
    float* m_rgba = (float*) malloc(w * h * 4 * sizeof(float));
    float* m_sharp = (float*) malloc(w * h * 4 * sizeof(float));

    int m = 0, w2 = w, h2 = h;
    while (m < (mipmaps ? numMipmaps : 1)) {
        success = stbir_resize_float_generic(
            f_rgba, w, h, w * 4 * sizeof(float),
            m_rgba, w2, h2, w2 * 4 * sizeof(float),
            4, // num_channels
            3, // alpha_channel
            0, // flags
            STBIR_EDGE_CLAMP,
            STBIR_FILTER_BOX,
            STBIR_COLORSPACE_LINEAR,
            NULL);
        if (!success) {
            fprintf(stderr, "Failed to resize image to %d x %d\n", w2, h2);
            return -1;
        }

        if (sharp) {
            sharpen_float(m_sharp, m_rgba, w2, h2, 4);
        }
        const float* input = sharp ? m_sharp : m_rgba;

        int output_size;
        if (type == KTX_UNSIGNED_SHORT_4_4_4_4) {
            rgba4_from_rgba(output, input, w2, h2);
            output_size = w2 * h2 * 2;
        } else if (type == KTX_UNSIGNED_SHORT_5_5_5_1) {
            rgba5551_from_rgba(output, input, w2, h2);
            output_size = w2 * h2 * 2;
        } else if (type == KTX_UNSIGNED_SHORT_5_6_5) {
            rgb565_from_rgba(output, input, w2, h2);
            output_size = w2 * h2 * 2;
        } else if (format == KTX_RGBA) {
            rgba8_from_rgba(output, input, w2, h2);
            output_size = w2 * h2 * 4;
        } else if (format == KTX_RGB) {
            rgb8_from_rgba(output, input, w2, h2);
            output_size = w2 * h2 * 3;
        } else if (format == KTX_LUMINANCE_ALPHA) {
            la8_from_rgba(output, input, w2, h2);
            output_size = w2 * h2 * 2;
        } else if (format == KTX_LUMINANCE) {
            l8_from_rgba(output, input, w2, h2);
            output_size = w2 * h2;
        } else if (format == KTX_ALPHA) {
            a8_from_rgba(output, input, w2, h2);
            output_size = w2 * h2;
        } else {
            fprintf(stderr, "Unexpected type/format combination: %d/%d\n", type, format);
            return -1;
        }

        success = ktx_append_mipmap(outfile, output, output_size);
        if (!success) {
            fprintf(stderr, "Failed to write %d x %d mipmap\n", w2, h2);
            return -1;
        }

        ++m;
        w2 = (w2 > 1) ? (w2 / 2) : 1;
        h2 = (h2 > 1) ? (h2 / 2) : 1;
    }

    return 0;
}
