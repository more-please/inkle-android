#include "package_reader.h"

#include <assert.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <zlib.h>
#include <iostream>
#include <string.h>

using namespace std;

PackageReader::PackageReader(const string& filename) {
    cerr << "Reading " << filename << "...\n";
    int fd = open(filename.c_str(), O_RDONLY);
    assert(fd > 0);

    long fileSize = lseek(fd, 0, SEEK_END);
    assert(fileSize > 0);

    const uint8_t* ptr = reinterpret_cast<const uint8_t*>(mmap(0, fileSize, PROT_READ, MAP_PRIVATE, fd, 0));
    assert(ptr != MAP_FAILED);

    const uint32_t* data = reinterpret_cast<const uint32_t*>(ptr);
    uint32_t dirOffset = data[3];
    assert(data[2] == fileSize);
    assert((dirOffset & 15) == 0);
    assert(fileSize >= dirOffset);

    uint32_t dirSize = (fileSize - dirOffset) / 20;

    for(uint32_t pos = dirOffset; pos < fileSize; pos += 20) {
        const uint32_t* d = data + (pos / 4);
        const uint32_t namePos = d[0];
        const uint32_t nameSize = d[1];
        const uint32_t dataPos = d[2];
        const uint32_t dataSize = d[3];
        const uint32_t fullSize = d[4];

        string name(&ptr[namePos], &ptr[namePos] + nameSize);
//         cerr << "  " << name << ": " << fullSize << " bytes";

        vector<char> bytes(&ptr[dataPos], &ptr[dataPos] + dataSize);
        if (dataSize != fullSize) {
//             cerr << " (" << dataSize << " compressed)";

            vector<char> decompressedBytes;
            decompressedBytes.resize(fullSize);

            z_stream z;
            memset(&z, 0, sizeof(z));
            z.next_in = (unsigned char*)&bytes[0];
            z.avail_in = dataSize;
            z.next_out = (unsigned char*)&decompressedBytes[0];
            z.avail_out = fullSize;

            int zerr = inflateInit(&z);
            assert(zerr == Z_OK);

            zerr = inflate(&z, Z_FINISH);
            assert(zerr == Z_STREAM_END);

            zerr = inflateEnd(&z);
            assert(zerr == Z_OK);

            bytes = decompressedBytes;
        }

//         cerr << "\n";
        _data[name] = bytes;
    }

//     cerr << "\n";
    cerr << "Reading " << filename << "... Done\n";

    int err = munmap((void*) ptr, fileSize);
    assert(err == 0);
}

void PackageReader::add(const PackageReader& other) {
    for (auto i : other._data) {
        add(i.first, i.second);
    }
}

void PackageReader::subtract(const PackageReader& other) {
    for (auto i : other._data) {
        subtract(i.first, i.second);
    }
}

void PackageReader::add(const string& name, const vector<char>& bytes) {
    _data[name] = bytes;
}

void PackageReader::subtract(const string& name, const vector<char>& bytes) {
    auto i = _data.find(name);
    if (i != _data.end() && i->second == bytes) {
//         cerr << "Removing " << name << "\n";
        _data.erase(i);
    }
}

void PackageReader::subtract_crc(const string& name, unsigned long their_crc) {
    auto i = _data.find(name);
    if (i != _data.end()) {
        auto bytes = i->second;
        unsigned long my_crc = crc32(0, NULL, 0);
        my_crc = crc32(my_crc, (const unsigned char*) &bytes[0], bytes.size());
        if (their_crc == my_crc) {
//             cerr << "Removing " << name << " (same CRC)\n";
            _data.erase(i);
        }
    }
}
