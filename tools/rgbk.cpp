#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "read_entire_file.h"
#include "separate_ink.h"

#include "stb_image.h"
#include "stb_image_write.h"

void usage() {
    fprintf(stderr,
        "Convert an RGB image to 'RGBK' format, with black overlay in the alpha channel.\n\n"
        "Usage: rgbk [-t threshold] [-i infile] [-o outfile]\n"
        "  -t, --threshold: maximum 8-bit luminosity of black pixels (default: 16)\n"
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
    int threshold = 16;
    for (int i = 1; i < argc; ++i) {
        const char* s = argv[i];
        if (isFlag(s, "-i", "--infile")) {
            infile = argv[++i];
        } else if (isFlag(s, "-o", "--outfile")) {
            outfile = fopen(argv[++i], "wb");
        } else if (isFlag(s, "-t", "--threshold")) {
            threshold = atoi(argv[++i]);
        } else {
            fprintf(stderr, "Bad argument '%s'\n\n", s);
            usage();
        }
    }

    std::vector<uint8_t> file = read_entire_file(infile);

    int w, h, comp;
    uint8_t* input = stbi_load_from_memory(&file[0], file.size(), &w, &h, &comp, 3);

    uint8_t* rgb = (uint8_t*) calloc(w * h, 3);
    uint8_t* ink = (uint8_t*) calloc(w * h, 1);

    separate_ink(rgb, ink, threshold, input, w, h);

    uint8_t* output = (uint8_t*) calloc(w * h, 4);

    const uint8_t* rgb_ptr = rgb;
    const uint8_t* inkPtr = ink;
    uint8_t* destPtr = output;
    for (int i = 0; i < w*h; ++i) {
        *destPtr++ = *rgb++;
        *destPtr++ = *rgb++;
        *destPtr++ = *rgb++;
        *destPtr++ = *ink++;
    }

    fprintf(stderr, "Writing output\n");
    stbi_write_png_to_file(outfile, w, h, 4, output, w * 4);
    return 0;
}
