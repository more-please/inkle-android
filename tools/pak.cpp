#include <assert.h>
#include <stdlib.h>
#include <unistd.h>

#include <iostream>
#include <vector>
#include <set>
#include <string>

#include "file_scanner.h"
#include "package_writer.h"

using namespace std;

void usage() {
    cerr << "Packs multiple files into a single .pak archive." << endl;
    cerr << "All specified files and directories are added." << endl << endl;
    cerr << "Usage: pak -o outfile [-i glob] [-x glob] [-c ext] paths..." << endl;
    cerr << "  -o, --outfile: output file (required)" << endl;
    cerr << "  -i, --include: glob for files to include (optional)" << endl;
    cerr << "  -x, --exclude: glob for files to exclude (optional)" << endl;
    cerr << "  -v, --verbose: list skipped files as well as added files" << endl;
    cerr << "  -c, --compress: compress files ending with the given extension(s)" << endl;
    cerr << "  -h, --help: show this help text" << endl << endl;
    flush(cerr);
    exit(1);
}

bool stringEndsWith(const string& s, const string& ext) {
    return (s.length() >= ext.length())
        && (0 == s.compare(s.length() - ext.length(), ext.length(), ext));
}

int main(int argc, const char* argv[]) {
    bool verbose = false;
    string outfile;
    vector<string> paths;
    vector<string> includes;
    vector<string> excludes;
    vector<string> compress;

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "-v" || arg == "--verbose") {
            verbose = true;
        } else if (arg == "-h" || arg == "--help") {
            usage();
        } else if (arg[0] == '-') {
            if ((i+1) >= argc) {
                cerr << "Missing argument for " << arg << endl << endl;
                usage();
            }
            string param = argv[++i];
            if (param.empty()) {
                cerr << "Missing argument for " << arg << endl << endl;
                usage();
            }
            if (arg == "-o" || arg == "--outfile") {
                if (!outfile.empty()) {
                    usage();
                }
                outfile = param;
            } else if (arg == "-i" || arg == "--include") {
                includes.push_back(param);
            } else if (arg == "-x" || arg == "--exclude") {
                excludes.push_back(param);
            } else if (arg == "-c" || arg == "--compress") {
                compress.push_back(param);
            } else {
                cerr << "Unknown flag: " << arg << endl << endl;
                usage();
            }
        } else {
            paths.push_back(arg);
        }
    }

    if (outfile.empty()) {
        cerr << "No output file specified! (use -o or --outfile)" << endl << endl;
        usage();
    }
    
    if (paths.empty()) {
        cerr << "No input files specified!" << endl << endl;
        usage();
    }

    excludes.push_back(outfile);

    FileScanner scanner(includes, excludes);
    scanner.verbose = verbose;
    for (vector<string>::iterator i = paths.begin(); i != paths.end(); ++i) {
        scanner.addFileOrDir(*i, "");
    }
    set<FileScanner::base_name> files = scanner.getFiles();

    PackageWriter writer(outfile.c_str());
    for (set<FileScanner::base_name>::iterator i = files.begin(); i != files.end(); ++i) {
        const string& base = i->first;
        const string& name = i->second;
        bool shouldCompress = false;
        for (vector<string>::iterator i = compress.begin(); i != compress.end(); ++i) {
            if (stringEndsWith(name, *i)) {
                shouldCompress = true;
            }
        }
        writer.addFile(
            name.c_str(),
            base.empty() ? name.c_str() : (base + "/" + name).c_str(),
            shouldCompress);
    }
    writer.commit();
}
