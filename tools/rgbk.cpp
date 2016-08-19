#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "blur.h"
#include "read_entire_file.h"
#include "separate_ink.h"

#include "stb_image.h"
#include "stb_image_write.h"

void usage() {
    fprintf(stderr,
        "Convert an RGB image to 'RGBA+K' format, with black overlay in the alpha channel.\n\n"
        "Usage: rgbk [-t threshold] [-i infile] [-o outfile] [-c colorfile] [-k inkfile]\n"
        "  -v, --verbose: print verbose progress info\n"
        "  -t, --threshold: maximum 8-bit luminosity of black pixels (default: 32)\n"
        "  -i, --infile: input file (default is stdin)\n"
        "  -o, --outfile: combined output file, black+alpha in alpha channel\n"
        "  -c, --color: RGB output file\n"
        "  -k, --ink: greyscale output file (encodes black+alpha)\n");
    fflush(stderr);
    exit(1);
}

bool isFlag(const char* s, const char* flag1, const char* flag2) {
    return strcmp(s, flag1) == 0 || strcmp(s, flag2) == 0;
}

static bool verbose = false;

__attribute__((format(printf, 1, 2)))
void vlog(const char* format, ...) {
    if (verbose) {
        va_list args;
        va_start(args, format);
        vfprintf(stderr, format, args);
        fprintf(stderr, "\n");
        va_end(args);
    }
}

int main(int argc, const char* argv[]) {
    const char* infile = NULL;
    const char* outfile = NULL;
    const char* outrgb = NULL;
    const char* outk = NULL;
    int threshold = 32;
    for (int i = 1; i < argc; ++i) {
        const char* s = argv[i];
        if (isFlag(s, "-i", "--infile")) {
            infile = argv[++i];
        } else if (isFlag(s, "-o", "--outfile")) {
            outfile = argv[++i];
        } else if (isFlag(s, "-c", "--color")) {
            outrgb = argv[++i];
        } else if (isFlag(s, "-k", "--ink")) {
            outk = argv[++i];
        } else if (isFlag(s, "-t", "--threshold")) {
            threshold = atoi(argv[++i]);
        } else if (isFlag(s, "-v", "--verbose")) {
            verbose = true;
        } else {
            fprintf(stderr, "Bad argument '%s'\n\n", s);
            usage();
        }
    }

    if (!infile) {
        usage();
    }

    vlog("Loading %s", infile);
    std::vector<uint8_t> file = read_entire_file(infile);

    int w, h, comp;
    uint8_t* input = stbi_load_from_memory(&file[0], file.size(), &w, &h, &comp, 4);

    vlog("Pre-multiplying alpha");
    for (int i = 0; i < w*h; ++i) {
        float a = input[4*i + 3] / 255.0;
        for (int j = 0; j < 3; ++j) {
            input[4*i + j] *= a;
        }
    }

    uint8_t* rgb = (uint8_t*) calloc(w * h, 4);
    float* ink = (float*) calloc(w * h, sizeof(float));

    vlog("Extracting RGB+K");
    separate_ink(rgb, ink, threshold, input, w, h);

    if (outrgb) {
        vlog("Writing RGB to %s", outrgb);
        FILE* f = fopen(outrgb, "wb");
        stbi_write_png_to_file(f, w, h, 4, rgb, w * 4);
        fclose(f);
    }

    if (outk || outfile) {
        vlog("Blurring K");

        // Half-pixel blur
        const float kernel[5] = { 0, 0.16, 0.68, 0.16, 0 };

        // One-pixel blur
//         const float kernel[5] = { 0.065, 0.24, 0.39, 0.24,  0.065 };

        blur5(ink, w, h, kernel);

        vlog("Combining A+K");
        uint8_t* k_plus_a = (uint8_t*) calloc(w * h, 1);
        for (int i = 0; i < w*h; ++i) {
            float k = ink[i];
            uint8_t a = input[4*i + 3];
            float combo = k;
            if (a == 255) {
                // Opaque: encode ink in the 0.25 - 1 range
                combo = 0.25 + 0.75 * k;
            } else {
                // Translucent black: encode alpha in the 0 - 0.25 range
                combo = 0.25 * (a / 255.0);
            }

            int n = combo * 255.0;
            if (n > 255) n = 255;
            if (n < 0) n = 0;
            k_plus_a[i] = n;
        }

        if (outk) {
            vlog("Writing A+K to %s", outk);
            FILE* f = fopen(outk, "wb");
            stbi_write_png_to_file(f, w, h, 1, k_plus_a, w);
            fclose(f);
        }

        if (outfile) {
            uint8_t* output = (uint8_t*) calloc(w * h, 4);

            const uint8_t* rgb_ptr = rgb;
            const uint8_t* ka_ptr = k_plus_a;
            uint8_t* destPtr = output;
            for (int i = 0; i < w*h; ++i) {
                *destPtr++ = *rgb_ptr++;
                *destPtr++ = *rgb_ptr++;
                *destPtr++ = *rgb_ptr++;
                *destPtr++ = *ka_ptr++;
            }

            vlog("Writing RGBA+K to %s", outfile);
            FILE* f = fopen(outfile, "wb");
            stbi_write_png_to_file(f, w, h, 4, output, w * 4);
            fclose(f);
        }
    }

    return 0;
}
