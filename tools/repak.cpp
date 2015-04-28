#include <assert.h>
#include <stdlib.h>
#include <unistd.h>

#include <iostream>
#include <vector>
#include <set>
#include <string>

#include "json.h"

#include "package_reader.h"
#include "package_writer.h"
#include "read_entire_file.h"

using namespace std;

void usage() {
    cerr << "Group multiple .pak archives into a single file." << endl;
    cerr << "Usage: repak [-o outfile] [-i glob] [-x glob] [-c ext]" << endl;
    cerr << "  -o, --outfile: output file" << endl;
    cerr << "  -i, --include: include this pak file" << endl;
    cerr << "  -x, --exclude: skip any resources in this pak file" << endl;
    cerr << "  --crc: skip any resources in this CRC file" << endl;
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
    vector<string> includes;
    vector<string> excludes;
    vector<string> crcs;
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
            } else if (arg == "--crc") {
                crcs.push_back(param);
            } else if (arg == "-c" || arg == "--compress") {
                compress.push_back(param);
            } else {
                cerr << "Unknown flag: " << arg << endl << endl;
                usage();
            }
        } else {
        	usage();
        }
    }

	PackageReader result;
	for (string include : includes) {
		result.add(PackageReader(include));
	}
	for (string exclude : excludes) {
		result.subtract(PackageReader(exclude));
	}
	for (string f : crcs) {
	    std::vector<unsigned char> bytes = read_entire_file(f.c_str());
	    json_value* json = json_parse((const char*) &bytes[0], bytes.size());
	    assert(json->type == json_object);
	    for (int i = 0; i < json->u.object.length; ++i) {
	        string name (
	            json->u.object.values[i].name,
	            json->u.object.values[i].name + json->u.object.values[i].name_length);
            assert(json->u.object.values[i].value->type == json_integer);
            unsigned long crc = json->u.object.values[i].value->u.integer;
            result.subtract_crc(name, crc);
	    }
	    json_value_free(json);
	}

    if (!outfile.empty()) {
		PackageWriter writer(outfile.c_str());
		for (auto d : result.data()) {
			const string& name = d.first;
			const vector<char>& bytes = d.second;
			bool shouldCompress = false;
			for (vector<string>::iterator i = compress.begin(); i != compress.end(); ++i) {
				if (stringEndsWith(name, *i)) {
					shouldCompress = true;
				}
			}
			writer.addData(
				name.c_str(),
				bytes.size(),
				&bytes[0],
				shouldCompress);
		}
		writer.commit();
	}
}
