#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "fix_alpha.h"
#include "read_entire_file.h"

#include "stb_image.h"
#include "stb_image_write.h"

void usage() {
    fprintf(stderr,
        "Shuffle the color channels of a PNG.\n\n"
        "Usage: swizzle -s [rgba01] [-i in.png] [-o out.png]\n\n"
        "  -s, --swizzle: exactly 4 channel identifiers (r/g/b/a) or constants (0/1)\n"
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
    const char* swizzle = NULL;
    int width = 0, height = 0, bpp = 0;
    for (int i = 1; i < argc; ++i) {
        const char* s = argv[i];
        if (isFlag(s, "-i", "--infile")) {
            infile = argv[++i];
        } else if (isFlag(s, "-o", "--outfile")) {
            outfile = fopen(argv[++i], "wb");
        } else if (isFlag(s, "-s", "--swizzle")) {
            swizzle = argv[++i];
        } else {
            fprintf(stderr, "Bad argument '%s'\n\n", s);
            usage();
        }
    }
    if (!swizzle || strlen(swizzle) != 4) {
        usage();
    }

    std::vector<unsigned char> file = read_entire_file(infile);

    int w, h, comp;
    unsigned char* input = stbi_load_from_memory(&file[0], file.size(), &w, &h, &comp, 4);

    fix_alpha(w, h, input);

    unsigned char* output = (unsigned char*) malloc(w * h * 4);
    for (int i = 0; i < (w * h * 4); i += 4) {
        for (int j = 0; j < 4; ++j) {
            unsigned char value = 0;
            unsigned char r = input[i], g = input[i+1], b = input[i+2], a = input[i+3];
            switch (swizzle[j]) {
                case 'r': case 'R': value = r; break;
                case 'g': case 'G': value = g; break;
                case 'b': case 'B': value = b; break;
                case 'a': case 'A': value = a; break;
                case '0': value = 0; break;
                case '1': value = 255; break;
                default:
                    fprintf(stderr, "Unknown swizzle character: %c\n", swizzle[j]);
                    abort();
            }
            output[i + j] = value;
        }
    }

    stbi_write_png_to_file(outfile, w, h, 4, output, w * 4);
    return 0;
}
