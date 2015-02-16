#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "read_entire_file.h"

#include "stb_image.h"
#include "stb_image_write.h"

void usage() {
    fprintf(stderr,
        "Remove transparent edges from the given image.\n\n"
        "Usage: trim [-i in.png] [-o out.png]\n\n"
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
    int width = 0, height = 0, bpp = 0;
    for (int i = 1; i < argc; ++i) {
        const char* s = argv[i];
        if (isFlag(s, "-i", "--infile")) {
            infile = argv[++i];
        } else if (isFlag(s, "-o", "--outfile")) {
            outfile = fopen(argv[++i], "wb");
        } else {
            fprintf(stderr, "Bad argument '%s'\n\n", s);
            usage();
        }
    }

    std::vector<unsigned char> file = read_entire_file(infile);

    int w, h, comp;
    unsigned char* data = stbi_load_from_memory(&file[0], file.size(), &w, &h, &comp, 4);

    int x0 = w, x1 = 0;
    int y0 = h, y1 = 0;
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            unsigned char alpha = data[4 * (x + y*w) + 3];
            if (alpha > 0) {
                if (x < x0) x0 = x;
                if (x >= x1) x1 = x+1;
                if (y < y0) y0 = y;
                if (y >= y1) y1 = y+1;
            }
        }
    }
    if (x0 > x1) x0 = x1;
    if (y0 > y1) y0 = y1;

    stbi_write_png_to_file(outfile, x1-x0, y1-y0, 4, data + (y0 * w + x0) * 4, w * 4);

    return 0;
}
