#pragma once

#include <iostream>
#include <fstream>
#include <iterator>
#include <vector>

inline std::vector<unsigned char> read_entire_file(const char* filename) {
    if (filename) {
        std::ifstream f(filename, std::ios::binary);
        return std::vector<unsigned char>(
            std::istreambuf_iterator<char>(f),
            std::istreambuf_iterator<char>());
    } else {
        return std::vector<unsigned char>(
            std::istreambuf_iterator<char>(std::cin),
            std::istreambuf_iterator<char>());
    }
}
