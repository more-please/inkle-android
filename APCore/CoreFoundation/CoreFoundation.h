#pragma once

#import <stdint.h>

#if __LLP64__
typedef unsigned long long CFTypeID;
typedef unsigned long long CFOptionFlags;
typedef unsigned long long CFHashCode;
typedef signed long long CFIndex;
#else
typedef unsigned long CFTypeID;
typedef unsigned long CFOptionFlags;
typedef unsigned long CFHashCode;
typedef signed long CFIndex;
#endif

typedef const void * CFTypeRef;

#if (__cplusplus)
#define NS_OPTIONS(_type, _name) _type _name; enum : _type
#else
#define NS_OPTIONS(_type, _name) enum _name : _type _name; enum _name : _type
#endif

#if !(__BIG_ENDIAN__ || __LITTLE_ENDIAN__)
#error "Endianness unknown!"
#endif

static inline uint16_t CFSwapInt16(uint16_t arg) {
    uint16_t result;
    result = (uint16_t)(((arg << 8) & 0xFF00) | ((arg >> 8) & 0xFF));
    return result;
}

static inline uint32_t CFSwapInt32(uint32_t arg) {
    uint32_t result;
    result = ((arg & 0xFF) << 24) | ((arg & 0xFF00) << 8) | ((arg >> 8) & 0xFF00) | ((arg >> 24) & 0xFF);
    return result;
}

static inline uint64_t CFSwapInt64(uint64_t arg) {
    union CFSwap {
        uint64_t sv;
        uint32_t ul[2];
    } tmp, result;
    tmp.sv = arg;
    result.ul[0] = CFSwapInt32(tmp.ul[1]); 
    result.ul[1] = CFSwapInt32(tmp.ul[0]);
    return result.sv;
}

static inline uint16_t CFSwapInt16BigToHost(uint16_t arg) {
#if __BIG_ENDIAN__
    return arg;
#else
    return CFSwapInt16(arg);
#endif
}

static inline uint32_t CFSwapInt32BigToHost(uint32_t arg) {
#if __BIG_ENDIAN__
    return arg;
#else
    return CFSwapInt32(arg);
#endif
}

static inline uint64_t CFSwapInt64BigToHost(uint64_t arg) {
#if __BIG_ENDIAN__
    return arg;
#else
    return CFSwapInt64(arg);
#endif
}

static inline uint16_t CFSwapInt16HostToBig(uint16_t arg) {
#if __BIG_ENDIAN__
    return arg;
#else
    return CFSwapInt16(arg);
#endif
}

static inline uint32_t CFSwapInt32HostToBig(uint32_t arg) {
#if __BIG_ENDIAN__
    return arg;
#else
    return CFSwapInt32(arg);
#endif
}

static inline uint64_t CFSwapInt64HostToBig(uint64_t arg) {
#if __BIG_ENDIAN__
    return arg;
#else
    return CFSwapInt64(arg);
#endif
}

static inline uint16_t CFSwapInt16LittleToHost(uint16_t arg) {
#if __LITTLE_ENDIAN__
    return arg;
#else
    return CFSwapInt16(arg);
#endif
}

static inline uint32_t CFSwapInt32LittleToHost(uint32_t arg) {
#if __LITTLE_ENDIAN__
    return arg;
#else
    return CFSwapInt32(arg);
#endif
}

static inline uint64_t CFSwapInt64LittleToHost(uint64_t arg) {
#if __LITTLE_ENDIAN__
    return arg;
#else
    return CFSwapInt64(arg);
#endif
}

static inline uint16_t CFSwapInt16HostToLittle(uint16_t arg) {
#if __LITTLE_ENDIAN__
    return arg;
#else
    return CFSwapInt16(arg);
#endif
}

static inline uint32_t CFSwapInt32HostToLittle(uint32_t arg) {
#if __LITTLE_ENDIAN__
    return arg;
#else
    return CFSwapInt32(arg);
#endif
}

static inline uint64_t CFSwapInt64HostToLittle(uint64_t arg) {
#if __LITTLE_ENDIAN__
    return arg;
#else
    return CFSwapInt64(arg);
#endif
}

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif
