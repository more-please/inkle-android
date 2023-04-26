#include "file_scanner.h"

#include <dirent.h>
#include <sys/stat.h>

#include <iostream>

using namespace std;

string join(const string& lhs, const string& rhs) {
    if (lhs.empty()) {
        return rhs;
    } else if (rhs.empty()) {
        return lhs;
    } else {
        return lhs + "/" + rhs;
    }
}

bool globMatch(const char* glob, const char* c) {
    switch(*glob) {
        case 0:
            // Empty glob, only matches empty string.
            return *c == 0;

        case '?':
            // Match any one character.
            if (*c == 0) {
                return false;
            }
            return globMatch(glob + 1, c + 1);

        case '*':
            // Match any number of characters (including zero).
            if (*c == 0) {
                return glob[1] == 0;
            }
            return globMatch(glob, c + 1) || globMatch(glob + 1, c + 1);

        default:
            return (*glob == *c) && globMatch(glob + 1, c + 1);
    }
}

bool globMatch(const string& glob, const string& c) {
    return globMatch(glob.c_str(), c.c_str());
}

void FileScanner::addFileOrDir(const string& base, const string& name) {
    string filename = join(base, name);
    struct stat s;
    stat(filename.c_str(), &s);
    if ((s.st_mode & S_IFMT) == S_IFDIR) {
        addDir(base, name);
    } else {
        addFile(base, name);
    }
}

void FileScanner::addDir(const string& base, const string& name) {
    string dirname = join(base, name);
    if (verbose) {
        cerr << dirname << endl;
    }
    DIR* dir = opendir(dirname.c_str());
    dirent* result;
    for (result = readdir(dir); result; result = readdir(dir)) {
        if (result->d_name[0] == '\0' || result->d_name[0] == '.') {
            continue;
        }
        if (stripDirectories) {
            addFileOrDir(join(base, name), string(result->d_name));
        } else {
            addFileOrDir(base, join(name, result->d_name));
        }
    }
    closedir(dir);
}

void FileScanner::addFile(const string& base, const string& name) {
    bool shouldInclude = _includes.empty();
    for (vector<string>::iterator i = _includes.begin(); i != _includes.end(); ++i) {
        const string& include = *i;
        if (globMatch(include, name)) {
            shouldInclude = true;
            break;
        }
    }
    if (!shouldInclude) {
        if (verbose) {
            cerr << "- (" << name << ")" << endl;
        }
        return;
    }
    for (vector<string>::iterator i = _excludes.begin(); i != _excludes.end(); ++i) {
        const string& exclude = *i;
        if (globMatch(exclude, name)) {
            if (verbose) {
                cerr << "- (" << name << ")" << endl;
            }
            return;
        }
    }
//     cerr << "+ " << name << endl;
    _files.insert(make_pair(base, name));
}
