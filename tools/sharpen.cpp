#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "read_entire_file.h"
#include "sharpen.h"

#include "stb_image.h"
#include "stb_image_resize.h"
#include "stb_image_write.h"

void usage() {
    fprintf(stderr,
        "Compress the dynamic range of the given image, then sharpen blacks and whites.\n\n"
        "Usage: sharpen [-i in.png] [-o out.png]\n\n"
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
    unsigned char* input = stbi_load_from_memory(&file[0], file.size(), &w, &h, &comp, 0);

    uint8_t* output = (uint8_t*) malloc(w * h * comp);
    sharpen(output, input, w, h, comp);

    stbi_write_png_to_file(outfile, w, h, comp, output, w * comp);

    return 0;
}
