#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "read_entire_file.h"

using namespace std;

void usage() {
    fprintf(stderr,
        "XOR two or more files together. All files must be the same size.\n"
        "Usage: xor [files] -o outfile\n"
        "  -v, --verbose: print verbose progress info\n"
        "  -o, --outfile: combined output file, black+alpha in alpha channel\n");
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
    vector<const char*> infiles;
    const char* outfile = NULL;
    for (int i = 1; i < argc; ++i) {
        const char* s = argv[i];
        if (isFlag(s, "-o", "--outfile")) {
            outfile = argv[++i];
        } else if (isFlag(s, "-v", "--verbose")) {
            verbose = true;
        } else if (s[0] == '-') {
            fprintf(stderr, "*** Unknown flag: %s\n\n", s);
            usage();
        } else {
            infiles.push_back(argv[i]);
        }
    }

    if (!outfile) {
        fprintf(stderr, "*** The --out flag is required\n\n");
        usage();
    }

    if (infiles.empty()) {
        fprintf(stderr, "*** At least one input file is required\n\n");
        usage();
    }

    vlog("Reading %s...", infiles[0]);
    vector<uint8_t> buffer = read_entire_file(infiles[0]);
    vlog("Reading %s... %d bytes", infiles[0], (int) buffer.size());

    for (int i = 1; i < infiles.size(); ++i) {
        vlog("XORing with %s", infiles[i]);
        vector<uint8_t> rhs = read_entire_file(infiles[i]);
        if (rhs.size() != buffer.size()) {
            fprintf(stderr, "*** Wrong size! %s is %d bytes, but %s is %d bytes\n",
                infiles[0], (int) buffer.size(), infiles[i], (int) rhs.size());
            fflush(stderr);
            exit(1);
        }

        for (int j = 0; j < buffer.size(); ++j) {
            buffer[j] ^= rhs[j];
        }
    }

    vlog("Writing %s...", outfile);

    FILE* f = fopen(outfile, "wb");
    size_t count = fwrite(&buffer[0], 1, buffer.size(), f);
    if (count != buffer.size()) {
        perror("*** Write failed");
        exit(1); 
    }
    fclose(f);

    vlog("Writing %s... Done", outfile);
    return 0;
}
