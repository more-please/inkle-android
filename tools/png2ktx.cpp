#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <string>
#include <iostream>

using namespace std;

string ANDROID_DIR = ".";

void sys(const string& cmd) {
//     cerr << cmd << endl;
    int status = system(cmd.c_str());
    assert(status == EXIT_SUCCESS);
}

void usage() {
    fprintf(stderr,
        "Converts a .png file to .ktx format (with ETC1 compression)\n\n"
        "Usage: png2ktx [-n] [-s] [-i in.png] [-o out.ktx]\n\n"
        "  -n, --nonperceptual: use non-perceptual error metric\n"
        "  -s, --slow: high-quality output\n"
        "  -i, --infile: input file (default is stdin)\n"
        "  -o, --outfile: output file (default is stdout)\n");
    fflush(stderr);
    exit(1);
}

bool isFlag(const char* s, const char* flag1, const char* flag2) {
    return strcmp(s, flag1) == 0 || strcmp(s, flag2) == 0;
}

int main(int argc, const char* argv[]) {
    ANDROID_DIR = argv[0];
    for (int i = ANDROID_DIR.size() - 1; i >= 0; --i) {
        if (ANDROID_DIR[i] == '/') {
            ANDROID_DIR = ANDROID_DIR.substr(0, i);
            break;
        }
    }
    ANDROID_DIR = ANDROID_DIR + "/../..";

    const char* infile = "-";
    const char* outfile = NULL;
    bool nonperceptual = false;
    bool slow = false;
    int width = 0, height = 0, bpp = 0;
    for (int i = 1; i < argc; ++i) {
        const char* s = argv[i];
        if (isFlag(s, "-i", "--infile")) {
            infile = argv[++i];
        } else if (isFlag(s, "-o", "--outfile")) {
            outfile = argv[++i];
        } else if (isFlag(s, "-n", "--nonperceptual")) {
            nonperceptual = true;
        } else if (isFlag(s, "-s", "--slow")) {
            slow = true;
        } else {
            fprintf(stderr, "Bad argument '%s'\n\n", s);
            usage();
        }
    }

    string binDir = ANDROID_DIR + "/3rd-party/bin";

    char scratch[22] = "/tmp/png2ktx.XXXXXXXX";
    mkdtemp(scratch);
    string tempDir(scratch);
    string ppmFile = tempDir + "/temp.ppm";
    string texFile = tempDir + "/temp.ktx";

    sys("cd " + binDir + " && ./convert " + infile + " " + ppmFile);
    sys("cd " + binDir + " && ./etcpack " + ppmFile + " " + tempDir
        + " -e " + (nonperceptual ? "nonperceptual" : "perceptual")
        + " -s " + (slow ? "slow" : "fast")
        + " -c etc1 -mipmaps -ktx");
    sys("rm " + ppmFile);
    if (outfile) {
        sys("mv " + texFile + " " + outfile);
    } else {
        sys("cat " + texFile);
        sys("rm " + texFile);
    }
    sys("rmdir " + tempDir);
    return 0;
}
