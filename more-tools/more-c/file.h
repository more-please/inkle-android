#ifndef MORE_C_FILE_H
#define MORE_C_FILE_H

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

extern uint8_t* more_file_read(const char* filename, size_t* out_size);
extern int more_file_write(const char* filename, const uint8_t* ptr, size_t size);

#ifdef __cplusplus
} // extern "C"
#endif

#ifdef MORE_FILE_IMPLEMENTATION

uint8_t* more_file_read(const char* filename, size_t* out_size) {
    if (out_size) {
        *out_size = 0;
    }

    FILE* f = fopen(filename, "rb");
    if (!f) {
        return NULL;
    }

    if (fseek(f, 0, SEEK_END)) {
        fclose(f);
        return NULL;
    }

    long size = ftell(f);
    if (size < 0) {
        fclose(f);
        return NULL;
    }

    if (fseek(f, 0, SEEK_SET)) {
        fclose(f);
        return NULL;
    }

    uint8_t* result = (uint8_t*) malloc(size);
    if (fread(result, 1, size, f) < size) {
        free(result);
        result = NULL;
    }

    fclose(f);

    if (out_size) {
        *out_size = (size_t) size;
    }
    return result;
}

int more_file_write(const char* filename, const uint8_t* ptr, size_t size) {
    FILE* f = fopen(filename, "wb");
    if (!f) {
        return 0;
    }
    int success = (fwrite(ptr, 1, size, f) == size);
    fclose(f);
    return success;
}

#endif // MORE_FILE_IMPLEMENTATION

#endif // MORE_C_FILE_H
