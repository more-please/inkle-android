#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "read_entire_file.h"

#include "stb_image.h"
#include "stb_image_resize.h"
#include "stb_image_write.h"

void usage() {
    fprintf(stderr,
        "Rotate each row of an image horizontally. Useful for fixing cube maps!\n\n"
        "Usage: rotate -r pixels [-i in.png] [-o out.png]\n\n"
        "  -r, --rotate: number of pixels to rotate\n"
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
    int width = 0, height = 0, bpp = 0, pixels = 0;
    for (int i = 1; i < argc; ++i) {
        const char* s = argv[i];
        if (isFlag(s, "-i", "--infile")) {
            infile = argv[++i];
        } else if (isFlag(s, "-o", "--outfile")) {
            outfile = fopen(argv[++i], "wb");
        } else if (isFlag(s, "-r", "--rotate")) {
            pixels = atoi(argv[++i]);
        } else {
            fprintf(stderr, "Bad argument '%s'\n\n", s);
            usage();
        }
    }

    std::vector<unsigned char> file = read_entire_file(infile);

    int w, h, comp;
    unsigned char* input = stbi_load_from_memory(&file[0], file.size(), &w, &h, &comp, 0);

    while (pixels < 0) {
        pixels += w;
    }
    while (pixels >= w) {
        pixels -= w;
    }
    std::vector<unsigned char> dest;
    dest.resize(w * h * comp);
    for (int row = 0; row < h; ++row) {
        for (int srcCol = 0; srcCol < (w * comp); ++srcCol) {
            int destCol = (srcCol + pixels * comp) % (w * comp);
            dest[row * w * comp + destCol] = input[row * w * comp + srcCol];
        }
    }
    
    stbi_write_png_to_file(outfile, w, h, comp, &dest[0], w * comp);

    return 0;
}
