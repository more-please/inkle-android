#pragma once

#include <stdlib.h>
#include <stdio.h>
#include <string>
#include <vector>

// Packs a collection of named data blobs into a single file, as follows:
//
// 8 bytes: signature
// 4 bytes: total file size, including header (always 16-byte aligned)
// 4 bytes: byte offset of directory (always 16-byte aligned)
// ...
// (data blobs, padded to 16 bytes each)
// (packed filenames, followed by 16-byte padding)
// ...
// Directory, with 20 bytes per data blob:
//   4 bytes: name offset
//   4 bytes: name size
//   4 bytes: data offset
//   4 bytes: data size
//   4 bytes: uncompressed data size
//
// If 'uncompressed data size' is different from 'data size', the data
// is compressed with zlib.
//
// The directory always extends to the end of the file, so the number
// of blobs is (total size - directory offset) / 20. The directory is
// an an abitrary order. (TODO: might be nice to sort the filenames.)
//
// All sizes and offsets are little-endian.
//
class PackageWriter {
public:
    PackageWriter(const char* filename);
    ~PackageWriter();

    void addData(const char* name, size_t size, const void* data, bool compress);
    void addFile(const char* name, const char* fullpath, bool compress);
    void commit();

private:
    FILE* _file;
    size_t _offset;

    void write(size_t size, const void* data);
    void write2(size_t);
    void write4(size_t);

    void padTo16();

    struct FileInfo {
        std::string name;
        size_t nameOffset;
        size_t dataOffset;
        size_t dataSize;
        size_t uncompressedSize;
    };
    std::vector<FileInfo> _info;
};
