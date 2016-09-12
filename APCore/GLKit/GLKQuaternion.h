#pragma once

#import <CoreGraphics/CoreGraphics.h>

#import <math.h>

// Windows doesn't define M_PI??
#ifndef M_PI
#define M_PI 3.141592653589793
#endif

#import "GLKVector3.h"
#import "GLKMatrix3.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmissing-braces"

union _GLKQuaternion
{
    struct { GLKVector3 v; float s; };
    struct { float x, y, z, w; };
    float q[4];
};
typedef union _GLKQuaternion GLKQuaternion;    

extern const GLKQuaternion GLKQuaternionIdentity; 

static inline GLKQuaternion GLKQuaternionMake(float x, float y, float z, float w) {
    GLKQuaternion q = { x, y, z, w };
    return q;
}

static inline GLKQuaternion GLKQuaternionMultiply(GLKQuaternion lhs, GLKQuaternion rhs) {
    GLKQuaternion result = {
        lhs.q[3] * rhs.q[0] +
        lhs.q[0] * rhs.q[3] +
        lhs.q[1] * rhs.q[2] -
        lhs.q[2] * rhs.q[1],

        lhs.q[3] * rhs.q[1] +
        lhs.q[1] * rhs.q[3] +
        lhs.q[2] * rhs.q[0] -
        lhs.q[0] * rhs.q[2],

        lhs.q[3] * rhs.q[2] +
        lhs.q[2] * rhs.q[3] +
        lhs.q[0] * rhs.q[1] -
        lhs.q[1] * rhs.q[0],

        lhs.q[3] * rhs.q[3] -
        lhs.q[0] * rhs.q[0] -
        lhs.q[1] * rhs.q[1] -
        lhs.q[2] * rhs.q[2]
    };
    return result;
}

static inline GLKQuaternion GLKQuaternionInvert(GLKQuaternion quaternion) {
#if defined(__ARM_NEON__)
    float32x4_t *q = (float32x4_t *)&quaternion;
    float32x4_t v = vmulq_f32(*q, *q);
    float32x2_t v2 = vpadd_f32(vget_low_f32(v), vget_high_f32(v));
    v2 = vpadd_f32(v2, v2);
    float32_t scale = 1.0f / vget_lane_f32(v2, 0);
    v = vmulq_f32(*q, vdupq_n_f32(scale));
    
    uint32_t signBit = 0x80000000;
    uint32_t zeroBit = 0x0;
    uint32x4_t mask = vdupq_n_u32(signBit);
    mask = vsetq_lane_u32(zeroBit, mask, 3);
    v = vreinterpretq_f32_u32(veorq_u32(vreinterpretq_u32_f32(v), mask));
    
    return *(GLKQuaternion *)&v;
#else
    float scale = 1.0f / (quaternion.q[0] * quaternion.q[0] + 
                          quaternion.q[1] * quaternion.q[1] +
                          quaternion.q[2] * quaternion.q[2] +
                          quaternion.q[3] * quaternion.q[3]);
    GLKQuaternion q = {
        -quaternion.q[0] * scale,
        -quaternion.q[1] * scale,
        -quaternion.q[2] * scale,
        quaternion.q[3] * scale
    };
    return q;
#endif
}

static inline GLKVector3 GLKQuaternionRotateVector3(GLKQuaternion quaternion, GLKVector3 vector)
{
    GLKQuaternion rotatedQuaternion = GLKQuaternionMake(vector.v[0], vector.v[1], vector.v[2], 0.0f);
    rotatedQuaternion = GLKQuaternionMultiply(GLKQuaternionMultiply(quaternion, rotatedQuaternion), GLKQuaternionInvert(quaternion));
    return GLKVector3Make(rotatedQuaternion.q[0], rotatedQuaternion.q[1], rotatedQuaternion.q[2]);
}

static inline GLKQuaternion GLKQuaternionMakeWithAngleAndAxis(float radians, float x, float y, float z)
{
    float halfAngle = radians * 0.5f;
    float scale = sinf(halfAngle);
    GLKQuaternion q = { scale * x, scale * y, scale * z, cosf(halfAngle) };
    return q;
}

static inline GLKQuaternion GLKQuaternionMakeWithAngleAndVector3Axis(float radians, GLKVector3 axisVector)
{
    return GLKQuaternionMakeWithAngleAndAxis(radians, axisVector.v[0], axisVector.v[1], axisVector.v[2]);
}

extern GLKQuaternion GLKQuaternionMakeWithMatrix3(GLKMatrix3 matrix);

static inline float GLKQuaternionLength(GLKQuaternion quaternion) {
#if defined(__ARM_NEON__)
    float32x4_t v = vmulq_f32(*(float32x4_t *)&quaternion,
                              *(float32x4_t *)&quaternion);
    float32x2_t v2 = vpadd_f32(vget_low_f32(v), vget_high_f32(v));
    v2 = vpadd_f32(v2, v2);
    return sqrt(vget_lane_f32(v2, 0)); 
#else
    return sqrt(quaternion.q[0] * quaternion.q[0] +
                quaternion.q[1] * quaternion.q[1] +
                quaternion.q[2] * quaternion.q[2] +
                quaternion.q[3] * quaternion.q[3]);
#endif
}

static inline GLKQuaternion GLKQuaternionNormalize(GLKQuaternion quaternion) {
    float scale = 1.0f / GLKQuaternionLength(quaternion);
#if defined(__ARM_NEON__)
    float32x4_t v = vmulq_f32(*(float32x4_t *)&quaternion,
                              vdupq_n_f32((float32_t)scale));
    return *(GLKQuaternion *)&v;
#else
    GLKQuaternion q = { quaternion.q[0] * scale, quaternion.q[1] * scale, quaternion.q[2] * scale, quaternion.q[3] * scale };
    return q;
#endif
}

static inline GLKQuaternion GLKQuaternionSlerp(GLKQuaternion lhs, GLKQuaternion rhs, float t) {
    // Just using normalized linear interpolation, based on this interesting article:
    // http://number-none.com/product/Understanding%20Slerp,%20Then%20Not%20Using%20It/
    float dot = lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z + lhs.w * rhs.w;
    if (dot < 0) {
        rhs.x = -rhs.x;
        rhs.y = -rhs.y;
        rhs.z = -rhs.z;
        rhs.w = -rhs.w;
    }
    GLKQuaternion result = {
        lhs.x + (rhs.x - lhs.x) * t,
        lhs.y + (rhs.y - lhs.y) * t,
        lhs.z + (rhs.z - lhs.z) * t,
        lhs.w + (rhs.w - lhs.w) * t,
    };
    return GLKQuaternionNormalize(result);
}

static inline float GLKQuaternionAngle(GLKQuaternion quaternion) {
    float angle = acosf(quaternion.w);
    float scale = sqrtf(quaternion.x * quaternion.x + quaternion.y * quaternion.y + quaternion.z * quaternion.z);

    const float kEpsilon = 1e-4;
    if ((scale > -kEpsilon && scale < kEpsilon)
        || (scale < 2.0f * M_PI + kEpsilon && scale > 2.0f * M_PI - kEpsilon)) {
        return 0;
    }

    return angle * 2;
}


#pragma clang diagnostic pop
