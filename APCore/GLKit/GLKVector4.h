#pragma once

#import <CoreGraphics/CoreGraphics.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmissing-braces"

union _GLKVector4
{
    struct { float x, y, z, w; };
    struct { float r, g, b, a; };
    struct { float s, t, p, q; };
    float v[4];
};
typedef union _GLKVector4 GLKVector4;

static inline GLKVector4 GLKVector4Make(float x, float y, float z, float w) {
    GLKVector4 v = { x, y, z, w };
    return v;
}

static inline float GLKVector4Length(GLKVector4 vector) {
#if defined(__ARM_NEON__)
    float32x4_t v = vmulq_f32(*(float32x4_t *)&vector,
                              *(float32x4_t *)&vector);
    float32x2_t v2 = vpadd_f32(vget_low_f32(v), vget_high_f32(v));
    v2 = vpadd_f32(v2, v2);
    return sqrt(vget_lane_f32(v2, 0));
#else
    return sqrt(vector.v[0] * vector.v[0] +
                vector.v[1] * vector.v[1] +
                vector.v[2] * vector.v[2] +
                vector.v[3] * vector.v[3]);
#endif
}

static inline BOOL GLKVector4AllEqualToVector4(GLKVector4 lhs, GLKVector4 rhs) {
    return lhs.v[0] == rhs.v[0]
        && lhs.v[1] == rhs.v[1]
        && lhs.v[2] == rhs.v[2]
        && lhs.v[3] == rhs.v[3];
}

static inline GLKVector4 GLKVector4Lerp(GLKVector4 a, GLKVector4 b, float t)
{
    return GLKVector4Make(
        a.x + t * (b.x - a.x),
        a.y + t * (b.y - a.y),
        a.z + t * (b.z - a.z),
        a.w + t * (b.w - a.w)
    );
}

#pragma clang diagnostic pop
