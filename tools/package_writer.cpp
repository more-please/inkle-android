#include "package_writer.h"

#include <assert.h>

using namespace std;

PackageWriter::PackageWriter(const char* filename) {
    _file = fopen(filename, "wb");
    assert(_file);

    // Leave 16 bytes for the header.
    for (int i = 0; i < 16; ++i) {
        fputc(0, _file);
    }
    _offset = 16;
}

void PackageWriter::commit() {
    // Write the filenames (tightly packed).
    
    for (vector<FileInfo>::iterator i = _info.begin(); i != _info.end(); ++i) {
        FileInfo& info = *i;
        info.nameOffset = _offset;
        write(info.name.size(), info.name.c_str());
    }
    padTo16();

    // Write the directory. Per item:
    //   4 bytes: name offset
    //   4 bytes: name size
    //   4 bytes: data offset
    //   4 bytes: data size

    size_t directoryOffset = _offset;
    for (vector<FileInfo>::iterator i = _info.begin(); i != _info.end(); ++i) {
        FileInfo& info = *i;
        write4(info.nameOffset);
        write4(info.name.size());
        write4(info.dataOffset);
        write4(info.dataSize);
    }

    // Rewind and write the file header:
    //   8 bytes: signature
    //   4 bytes: file size
    //   4 bytes: directory offset

    size_t totalSize = _offset;
    fseek(_file, 0, SEEK_SET);
    _offset = 0;

    write(8, "AP_Pack!");
    write4(totalSize);
    write4(directoryOffset);

    fclose(_file);
    _file = 0;
}

PackageWriter::~PackageWriter() {
    if (_file) {
        fclose(_file);
    }
}

void PackageWriter::addData(const char *name, size_t size, const void *data, bool compress) {
    assert(_file);

    FileInfo info;
    info.name = name;
    info.dataOffset = _offset;
    info.dataSize = size;
    _info.push_back(info);

    write(size, data);
    padTo16();
}

void PackageWriter::addFile(const char* name, const char* path, bool compress) {
    FILE* f = fopen(path, "rb");
    assert(f);

    fseek(f, 0, SEEK_END);
    int size = ftell(f);
    fseek(f, 0, SEEK_SET);

    char* buffer = (char*) malloc(size);
    size_t bytesRead = fread(buffer, 1, size, f);
    assert(bytesRead == size);
    assert(!ferror(f));
    fclose(f);

    addData(name, size, buffer, compress);
    free(buffer);
}

void PackageWriter::write(size_t size, const void *data) {
    size_t written = fwrite(data, 1, size, _file);
    assert(written == size);
    _offset += size;
}

void PackageWriter::write2(size_t value) {
    fputc(value & 255, _file);
    fputc((value >> 8) & 255, _file);
    _offset += 2;
}

void PackageWriter::write4(size_t value) {
    fputc(value & 255, _file);
    fputc((value >> 8) & 255, _file);
    fputc((value >> 16) & 255, _file);
    fputc((value >> 24) & 255, _file);
    _offset += 4;
}

void PackageWriter::padTo16() {
    for (size_t paddedOffset = (_offset + 15) & ~15; _offset < paddedOffset; ++_offset) {
        fputc(0, _file);
    }
}
