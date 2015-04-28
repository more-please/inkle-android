#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "stb_image_write.h"

void superellipse(const char* filename, int size, double border, bool gradient, double exponent) {
    unsigned char* data = (unsigned char*) malloc(size * size);
    double center = size / 2;
    double radius = center - border;
    for (int y = 0; y < size; ++y) {
        double yf = fabs(y - center + 0.5) / radius;
        for (int x = 0; x < size; ++x) {
            double xf = fabs(x - center + 0.5) / radius;
            unsigned char* c = &data[y * size + x];
            double f = pow(xf, exponent) + pow(yf, exponent);
            if (gradient) {
                if (f < 0) f = 0;
                if (f > 1) f = 1;
                *c = 255 * (1 - f);
            } else {
                *c = (f < 1) ? 0 : 255;
            }
        }
    }
    stbi_write_png(filename, size, size, 1, (const char*) data, size);
    free(data);
}

void usage() {
    fprintf(stderr,
        "Generates a PNG image containing a superellipse.\n\n"
        "Usage: superellipse -o outfile [-s size] [-b border]\n"
        "  -o, --outfile: output file (required)\n"
        "  -s, --size: size in pixels (default 1024)\n"
        "  -b, --border: border in pixels (default 128)\n"
        "  -g, --gradient: generate shaded rather than solid output\n"
        "  -e, --exponent: exponent of the superellipse (default 2.0)\n\n");
    fflush(stderr);
    exit(1);
}

bool isFlag(const char* s, const char* flag1, const char* flag2) {
    return strcmp(s, flag1) == 0 || strcmp(s, flag2) == 0;
}

int main(int argc, const char* argv[]) {
    const char* outfile = NULL;
    int size = 1024;
    double border = 128;
    double exponent = 2.0;
    bool gradient = false;
    for (int i = 1; i < argc; ++i) {
        const char* s = argv[i];
        if (isFlag(s, "-o", "--outfile")) {
            outfile = argv[++i];
        } else if (isFlag(s, "-s", "--size")) {
            size = atoi(argv[++i]);
        } else if (isFlag(s, "-b", "--border")) {
            border = strtod(argv[++i], NULL);
        } else if (isFlag(s, "-e", "--exponent")) {
            exponent = strtod(argv[++i], NULL);
        } else if (isFlag(s, "-g", "--gradient")) {
            gradient = true;
        } else {
            fprintf(stderr, "Bad argument '%s'\n\n", s);
            usage();
        }
    }
    if (!outfile) {
        fprintf(stderr, "Missing --outfile\n\n");
        usage();
    }
    superellipse(outfile, size, border, gradient, exponent);
    return 0;
}
