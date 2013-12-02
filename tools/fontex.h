#ifndef _fontex_h
#define _fontex_h

#include <stdint.h>

#ifdef __cplusplus
namespace fontex {
#endif

typedef struct Header {
    char magic[8]; // 'fontex02'
    int16_t numGlyphs;
    int16_t numLigatures;
    int16_t numKerningPairs;
    int16_t ascent;
    int16_t descent;
    int16_t leading;
    int16_t emSize;
    int16_t textureSize;
    float textureScale;
    int16_t reserved[2];
} fontex_header_t;

typedef struct Glyph {
    uint16_t codepoint;
    int16_t advance; // Horizontal distance to next character
    int16_t x0, y0, x1, y1; // Bounding box relative to glyph origin
    uint16_t xTex, yTex; // Location in texture

#ifdef __cplusplus
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
#endif
} fontex_glyph_t;

typedef struct Ligature {
    uint16_t lhs;
    uint16_t rhs;
    uint16_t ligature;
} fontex_ligature_t;

typedef struct KerningPair {
    uint16_t lhs;
    uint16_t rhs;
    int16_t advance;
} fontex_kerning_pair_t;

#ifdef __cplusplus
inline bool operator<(const Ligature& lhs, const Ligature& rhs) {
    if (lhs.lhs != rhs.lhs) return lhs.lhs < rhs.lhs;
    if (lhs.rhs != rhs.rhs) return lhs.rhs < rhs.rhs;
    return false;
}

inline bool operator<(const KerningPair& lhs, const KerningPair& rhs) {
    if (lhs.lhs != rhs.lhs) return lhs.lhs < rhs.lhs;
    if (lhs.rhs != rhs.rhs) return lhs.rhs < rhs.rhs;
    return false;
}

} // namespace fontex
#endif

#endif // _fontex_h
