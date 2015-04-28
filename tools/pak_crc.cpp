#include <stdlib.h>
#include <unistd.h>
#include <zlib.h>

#include <iostream>
#include <string>

#include "package_reader.h"

using namespace std;

void usage() {
    cerr << "Prints the CRC32 of each item in the given .pak archive (in JSON format)" << endl;
    cerr << "Usage: pak_crc file" << endl;
    cerr << "  -h, --help: show this help text" << endl << endl;
    flush(cerr);
    exit(1);
}

int main(int argc, const char* argv[]) {
    vector<string> paths;

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "-h" || arg == "--help") {
            usage();
        } else {
            paths.push_back(arg);
        }
    }

    if (paths.empty()) {
        cerr << "No input files specified!" << endl << endl;
        usage();
    }

	PackageReader reader;
	for (string path : paths) {
		reader.add(PackageReader(path));
	}

    cout << "{";
    bool firstLine = true;
    auto data = reader.data();
    for (auto item : data) {
        const string& name = item.first;
        const vector<char>& bytes = item.second;
        unsigned long crc = crc32(0, NULL, 0);
        crc = crc32(crc, (const unsigned char*) &bytes[0], bytes.size());
        if (!firstLine) {
            cout << ",";
        }
        firstLine = false;
        cout << "\n\t\"" << name << "\": " << crc;
    }
    cout << "\n}\n";
}
