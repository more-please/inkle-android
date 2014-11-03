#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "fix_alpha.h"

#include "stb_image.h"
#include "stb_image_write.h"

void usage() {
    fprintf(stderr,
        "Turn an RGBA image into RGB, with the alpha channel appended horizontally.\n\n"
        "Usage: separate_alpha [-i in.png] [-o out.png]\n\n"
        "  -i, --infile: input file (default is stdin)\n"
        "  -o, --outfile: output file (default is stdout)\n");
    fflush(stderr);
    exit(1);
}

bool isFlag(const char* s, const char* flag1, const char* flag2) {
    return strcmp(s, flag1) == 0 || strcmp(s, flag2) == 0;
}

int main(int argc, const char* argv[]) {
    FILE* infile = stdin;
    FILE* outfile = stdout;
    int width = 0, height = 0, bpp = 0;
    for (int i = 1; i < argc; ++i) {
        const char* s = argv[i];
        if (isFlag(s, "-i", "--infile")) {
            infile = fopen(argv[++i], "rb");
        } else if (isFlag(s, "-o", "--outfile")) {
            outfile = fopen(argv[++i], "wb");
        } else {
            fprintf(stderr, "Bad argument '%s'\n\n", s);
            usage();
        }
    }

    int w, h, comp;
    unsigned char* input = stbi_load_from_file(infile, &w, &h, &comp, 4);

    fix_alpha(w, h, input);

    unsigned char* output = (unsigned char*) malloc(w * 2 * h * 3);
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            const unsigned char* rgba = &(input[4 * (x + y*w)]);
            unsigned char* rgb = &(output[3 * (x + y*2*w)]);
            unsigned char* a = rgb + 3*w;
            for (int i = 0; i < 3; ++i) {
                rgb[i] = rgba[i];
                a[i] = rgba[3];
            }
        }
    }
    stbi_write_png_to_file(outfile, w * 2, h, 3, output, w * 6);
    return 0;
}
