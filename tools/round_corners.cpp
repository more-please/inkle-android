#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "read_entire_file.h"
#include "stb_image.h"
#include "stb_image_write.h"

void round_corners(uint8_t* rgba, int width, int height, int corner) {
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            uint8_t& alpha = rgba[(y*width + x) * 4 + 3];
            if (x > corner && x < (width - corner)) {
                alpha = 255;
                continue;
            }
            if (y > corner && y < (height - corner)) {
                alpha = 255;
                continue;
            }
            const int i = (x <= corner) ? (x - corner) : (x + corner - width); 
            const int j = (y <= corner) ? (y - corner) : (y + corner - height); 
            uint8_t a = 0;
            for (int x2 = 0; x2 < 16; ++x2) {
                for (int y2 = 0; y2 < 16; ++y2) {
                    const double x3 = i + (x2 + 0.5) / 16.0;
                    const double y3 = j + (y2 + 0.5) / 16.0;
                    if ((x3 * x3 + y3 * y3) <= (corner * corner) && a < 255) {
                        ++a;
                    }
                }
            }
            alpha = a;
        }
    }
}

void usage() {
    fprintf(stderr,
        "Rounds off the corners of the given PNG image.\n\n"
        "Usage: round_corners -o outfile [-s size] [-b border]\n"
        "  -i, --infile: input file (default is stdin)\n"
        "  -o, --outfile: output file (default is stdout)\n"
        "  -c, --corner: corner radius in pixels (default is 1/16th of image width)\n");
    fflush(stderr);
    exit(1);
}

bool isFlag(const char* s, const char* flag1, const char* flag2) {
    return strcmp(s, flag1) == 0 || strcmp(s, flag2) == 0;
}

int main(int argc, const char* argv[]) {
    const char* infile = NULL;
    FILE* outfile = stdout;
    int corner = 0;
    for (int i = 1; i < argc; ++i) {
        const char* s = argv[i];
        if (isFlag(s, "-i", "--infile")) {
            infile = argv[++i];
        } else if (isFlag(s, "-o", "--outfile")) {
            outfile = fopen(argv[++i], "wb");
        } else if (isFlag(s, "-c", "--corner")) {
            corner = atoi(argv[++i]);
        } else {
            fprintf(stderr, "Bad argument '%s'\n\n", s);
            usage();
        }
    }

    std::vector<uint8_t> file = read_entire_file(infile);

    int w, h, comp;
    uint8_t* input = stbi_load_from_memory(&file[0], file.size(), &w, &h, &comp, 4);
    if (!input) {
        fprintf(stderr, "Error loading input image: %s\n", stbi_failure_reason());
        exit(1);
    }

    if (corner <= 0) {
        corner = w / 16;
    }

    round_corners(input, w, h, corner);

    stbi_write_png_to_file(outfile, w, h, 4, input, w * 4);
    return 0;
}
