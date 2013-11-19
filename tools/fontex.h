#ifndef _fontex_h
#define _fontex_h

#include <sys/types.h>

namespace fontex {

typedef short int16_t;
typedef unsigned short uint16_t;

struct Header {
    char magic[2]; // 'fx'
    int16_t ascent;
    int16_t descent;
    int16_t leading;
    int16_t emSize;
    int16_t numGlyphs;
    int16_t numLigatures;
    int16_t numKerningPairs;
};

struct Glyph {
    uint16_t codepoint;
    int16_t advance; // Horizontal distance to next character
    int16_t x0, y0, x1, y1; // Bounding box relative to glyph origin
    int16_t xTex, yTex; // Top-left of texture coordinates

    int width() const { return x1 - x0; }
    int height() const { return y1 - y0; }

    struct CodepointCmp {
        bool operator()(const Glyph& lhs, const Glyph& rhs) {
            return lhs.codepoint < rhs.codepoint;
        }
    };

    struct SizeCmp {
        bool operator()(const Glyph& lhs, const Glyph& rhs) {
            if (lhs.height() != rhs.height()) return lhs.height() > rhs.height();
            if (lhs.width() != rhs.width()) return lhs.width() > rhs.width();
            return CodepointCmp()(lhs, rhs);
        }
    };
};

struct Ligature {
    uint16_t lhs;
    uint16_t rhs;
    uint16_t ligature;
};

inline bool operator<(const Ligature& lhs, const Ligature& rhs) {
    if (lhs.lhs != rhs.lhs) return lhs.lhs < rhs.lhs;
    if (lhs.rhs != rhs.rhs) return lhs.rhs < rhs.rhs;
    return false;
}

struct KerningPair {
    uint16_t lhs;
    uint16_t rhs;
    int16_t advance;
};

inline bool operator<(const KerningPair& lhs, const KerningPair& rhs) {
    if (lhs.lhs != rhs.lhs) return lhs.lhs < rhs.lhs;
    if (lhs.rhs != rhs.rhs) return lhs.rhs < rhs.rhs;
    return false;
}

} // namespace fontex

#endif // _fontex_h
