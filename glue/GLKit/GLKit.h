#pragma once

#import <CoreGraphics/CoreGraphics.h>

#import "GLKViewController.h"

union _GLKVector2
{
    struct { float x, y; };
    struct { float s, t; };
    float v[2];
} __attribute__((aligned(8)));
typedef union _GLKVector2 GLKVector2;

union _GLKVector3
{
    struct { float x, y, z; };
    struct { float r, g, b; };
    struct { float s, t, p; };
    float v[3];
};
typedef union _GLKVector3 GLKVector3;

union _GLKVector4
{
    struct { float x, y, z, w; };
    struct { float r, g, b, a; };
    struct { float s, t, p, q; };
    float v[4];
} __attribute__((aligned(16)));
typedef union _GLKVector4 GLKVector4;

union _GLKMatrix3
{
    struct
    {
        float m00, m01, m02;
        float m10, m11, m12;
        float m20, m21, m22;
    };
    float m[9];
};
typedef union _GLKMatrix3 GLKMatrix3;

union _GLKMatrix4
{
    struct
    {
        float m00, m01, m02, m03;
        float m10, m11, m12, m13;
        float m20, m21, m22, m23;
        float m30, m31, m32, m33;
    };
    float m[16];
} __attribute__((aligned(16)));
typedef union _GLKMatrix4 GLKMatrix4;

union _GLKQuaternion
{
    struct { GLKVector3 v; float s; };
    struct { float x, y, z, w; };
    float q[4];
} __attribute__((aligned(16)));
typedef union _GLKQuaternion GLKQuaternion;    

extern const GLKMatrix3 GLKMatrix3Identity;
extern const GLKMatrix4 GLKMatrix4Identity;

static inline GLKVector2 GLKVector2Make(float x, float y) {
    GLKVector2 v = { x, y };
    return v;
}

static inline GLKVector3 GLKVector3Make(float x, float y, float z) {
    GLKVector3 v = { x, y, z };
    return v;
}

static inline GLKVector3 GLKVector3Negate(GLKVector3 vector) {
    GLKVector3 v = { -vector.v[0], -vector.v[1], -vector.v[2] };
    return v;
}
    
static inline float GLKVector3Length(GLKVector3 vector) {
    return sqrt(vector.v[0] * vector.v[0] + vector.v[1] * vector.v[1] + vector.v[2] * vector.v[2]);
}

static inline GLKVector3 GLKVector3Normalize(GLKVector3 vector) {
    float scale = 1.0f / GLKVector3Length(vector);
    GLKVector3 v = {
        vector.v[0] * scale,
        vector.v[1] * scale,
        vector.v[2] * scale
    };
    return v;
}
    
static inline float GLKVector3DotProduct(GLKVector3 vectorLeft, GLKVector3 vectorRight) {
    return vectorLeft.v[0] * vectorRight.v[0] + vectorLeft.v[1] * vectorRight.v[1] + vectorLeft.v[2] * vectorRight.v[2];
}

static inline GLKVector3 GLKVector3CrossProduct(GLKVector3 vectorLeft, GLKVector3 vectorRight) {
    GLKVector3 v = {
        vectorLeft.v[1] * vectorRight.v[2] - vectorLeft.v[2] * vectorRight.v[1],
        vectorLeft.v[2] * vectorRight.v[0] - vectorLeft.v[0] * vectorRight.v[2],
        vectorLeft.v[0] * vectorRight.v[1] - vectorLeft.v[1] * vectorRight.v[0]
    };
    return v;
}

static inline GLKVector4 GLKVector4Make(float x, float y, float z, float w) {
    GLKVector4 v = { x, y, z, w };
    return v;
}

static inline GLKMatrix3 GLKMatrix3Make(
    float m00, float m01, float m02,
    float m10, float m11, float m12,
    float m20, float m21, float m22)
{
    GLKMatrix3 result = {
        m00, m01, m02,
        m10, m11, m12,
        m20, m21, m22
    };
    return result;
}

static inline GLKMatrix3 GLKMatrix3MakeWithRows(
    GLKVector3 row0, GLKVector3 row1, GLKVector3 row2)
{
    GLKMatrix3 result = {
        row0.v[0], row1.v[0], row2.v[0],
        row0.v[1], row1.v[1], row2.v[1],
        row0.v[2], row1.v[2], row2.v[2]
    };
    return result;
}

static inline GLKMatrix3 GLKMatrix3MakeWithColumns(
    GLKVector3 column0, GLKVector3 column1, GLKVector3 column2)
{
    GLKMatrix3 result = {
        column0.v[0], column0.v[1], column0.v[2],
        column1.v[0], column1.v[1], column1.v[2],
        column2.v[0], column2.v[1], column2.v[2]
    };
    return result;
}

static inline GLKMatrix4 GLKMatrix4Make(
    float m00, float m01, float m02, float m03,
    float m10, float m11, float m12, float m13,
    float m20, float m21, float m22, float m23,
    float m30, float m31, float m32, float m33)
{
    GLKMatrix4 result = {
        m00, m01, m02, m03,
        m10, m11, m12, m13,
        m20, m21, m22, m23,
        m30, m31, m32, m33
    };
    return result;
}

static inline GLKMatrix4 GLKMatrix4Multiply(GLKMatrix4 lhs, GLKMatrix4 rhs)
{
#if defined(__ARM_NEON__)
    float32x4x4_t ilhs = *(float32x4x4_t *)&lhs;
    float32x4x4_t irhs = *(float32x4x4_t *)&rhs;
    float32x4x4_t m;

    m.val[0] = vmulq_n_f32(ilhs.val[0], vgetq_lane_f32(irhs.val[0], 0));
    m.val[1] = vmulq_n_f32(ilhs.val[0], vgetq_lane_f32(irhs.val[1], 0));
    m.val[2] = vmulq_n_f32(ilhs.val[0], vgetq_lane_f32(irhs.val[2], 0));
    m.val[3] = vmulq_n_f32(ilhs.val[0], vgetq_lane_f32(irhs.val[3], 0));

    m.val[0] = vmlaq_n_f32(m.val[0], ilhs.val[1], vgetq_lane_f32(irhs.val[0], 1));
    m.val[1] = vmlaq_n_f32(m.val[1], ilhs.val[1], vgetq_lane_f32(irhs.val[1], 1));
    m.val[2] = vmlaq_n_f32(m.val[2], ilhs.val[1], vgetq_lane_f32(irhs.val[2], 1));
    m.val[3] = vmlaq_n_f32(m.val[3], ilhs.val[1], vgetq_lane_f32(irhs.val[3], 1));

    m.val[0] = vmlaq_n_f32(m.val[0], ilhs.val[2], vgetq_lane_f32(irhs.val[0], 2));
    m.val[1] = vmlaq_n_f32(m.val[1], ilhs.val[2], vgetq_lane_f32(irhs.val[1], 2));
    m.val[2] = vmlaq_n_f32(m.val[2], ilhs.val[2], vgetq_lane_f32(irhs.val[2], 2));
    m.val[3] = vmlaq_n_f32(m.val[3], ilhs.val[2], vgetq_lane_f32(irhs.val[3], 2));

    m.val[0] = vmlaq_n_f32(m.val[0], ilhs.val[3], vgetq_lane_f32(irhs.val[0], 3));
    m.val[1] = vmlaq_n_f32(m.val[1], ilhs.val[3], vgetq_lane_f32(irhs.val[1], 3));
    m.val[2] = vmlaq_n_f32(m.val[2], ilhs.val[3], vgetq_lane_f32(irhs.val[2], 3));
    m.val[3] = vmlaq_n_f32(m.val[3], ilhs.val[3], vgetq_lane_f32(irhs.val[3], 3));

    return *(GLKMatrix4 *)&m;
#else
    GLKMatrix4 m;
    
    m.m[0]  = lhs.m[0] * rhs.m[0]  + lhs.m[4] * rhs.m[1]  + lhs.m[8] * rhs.m[2]   + lhs.m[12] * rhs.m[3];
	m.m[4]  = lhs.m[0] * rhs.m[4]  + lhs.m[4] * rhs.m[5]  + lhs.m[8] * rhs.m[6]   + lhs.m[12] * rhs.m[7];
	m.m[8]  = lhs.m[0] * rhs.m[8]  + lhs.m[4] * rhs.m[9]  + lhs.m[8] * rhs.m[10]  + lhs.m[12] * rhs.m[11];
	m.m[12] = lhs.m[0] * rhs.m[12] + lhs.m[4] * rhs.m[13] + lhs.m[8] * rhs.m[14]  + lhs.m[12] * rhs.m[15];
    
	m.m[1]  = lhs.m[1] * rhs.m[0]  + lhs.m[5] * rhs.m[1]  + lhs.m[9] * rhs.m[2]   + lhs.m[13] * rhs.m[3];
	m.m[5]  = lhs.m[1] * rhs.m[4]  + lhs.m[5] * rhs.m[5]  + lhs.m[9] * rhs.m[6]   + lhs.m[13] * rhs.m[7];
	m.m[9]  = lhs.m[1] * rhs.m[8]  + lhs.m[5] * rhs.m[9]  + lhs.m[9] * rhs.m[10]  + lhs.m[13] * rhs.m[11];
	m.m[13] = lhs.m[1] * rhs.m[12] + lhs.m[5] * rhs.m[13] + lhs.m[9] * rhs.m[14]  + lhs.m[13] * rhs.m[15];
    
	m.m[2]  = lhs.m[2] * rhs.m[0]  + lhs.m[6] * rhs.m[1]  + lhs.m[10] * rhs.m[2]  + lhs.m[14] * rhs.m[3];
	m.m[6]  = lhs.m[2] * rhs.m[4]  + lhs.m[6] * rhs.m[5]  + lhs.m[10] * rhs.m[6]  + lhs.m[14] * rhs.m[7];
	m.m[10] = lhs.m[2] * rhs.m[8]  + lhs.m[6] * rhs.m[9]  + lhs.m[10] * rhs.m[10] + lhs.m[14] * rhs.m[11];
	m.m[14] = lhs.m[2] * rhs.m[12] + lhs.m[6] * rhs.m[13] + lhs.m[10] * rhs.m[14] + lhs.m[14] * rhs.m[15];
    
	m.m[3]  = lhs.m[3] * rhs.m[0]  + lhs.m[7] * rhs.m[1]  + lhs.m[11] * rhs.m[2]  + lhs.m[15] * rhs.m[3];
	m.m[7]  = lhs.m[3] * rhs.m[4]  + lhs.m[7] * rhs.m[5]  + lhs.m[11] * rhs.m[6]  + lhs.m[15] * rhs.m[7];
	m.m[11] = lhs.m[3] * rhs.m[8]  + lhs.m[7] * rhs.m[9]  + lhs.m[11] * rhs.m[10] + lhs.m[15] * rhs.m[11];
	m.m[15] = lhs.m[3] * rhs.m[12] + lhs.m[7] * rhs.m[13] + lhs.m[11] * rhs.m[14] + lhs.m[15] * rhs.m[15];
    
    return m;
#endif
}

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

extern GLKQuaternion GLKQuaternionMakeWithMatrix3(GLKMatrix3 matrix);
