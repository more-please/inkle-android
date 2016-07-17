#pragma once

#import <CoreGraphics/CoreGraphics.h>

#import "GLKVector3.h"
#import "GLKVector4.h"
#import "GLKQuaternion.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmissing-braces"

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
};
typedef union _GLKMatrix4 GLKMatrix4;

extern const GLKMatrix4 GLKMatrix4Identity;

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

static inline GLKMatrix4 GLKMatrix4MakeOrtho(
    float left, float right,
    float bottom, float top,
    float nearZ, float farZ)
{
    float ral = right + left;
    float rsl = right - left;
    float tab = top + bottom;
    float tsb = top - bottom;
    float fan = farZ + nearZ;
    float fsn = farZ - nearZ;

    GLKMatrix4 result = {
        2.0f / rsl, 0.0f, 0.0f, 0.0f,
        0.0f, 2.0f / tsb, 0.0f, 0.0f,
        0.0f, 0.0f, -2.0f / fsn, 0.0f,
        -ral / rsl, -tab / tsb, -fan / fsn, 1.0f
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

extern GLKMatrix4 GLKMatrix4Invert(GLKMatrix4 matrix, bool *isInvertible);
extern GLKMatrix4 GLKMatrix4InvertAndTranspose(GLKMatrix4 matrix, bool *isInvertible);

static inline GLKMatrix4 GLKMatrix4MakePerspective(float fovyRadians, float aspect, float nearZ, float farZ) {
    float cotan = 1.0f / tanf(fovyRadians / 2.0f);
    GLKMatrix4 m = { cotan / aspect, 0.0f, 0.0f, 0.0f,
                     0.0f, cotan, 0.0f, 0.0f,
                     0.0f, 0.0f, (farZ + nearZ) / (nearZ - farZ), -1.0f,
                     0.0f, 0.0f, (2.0f * farZ * nearZ) / (nearZ - farZ), 0.0f
    };
    return m;
}

static inline GLKMatrix4 GLKMatrix4MakeFrustum(
    float left, float right, float bottom, float top, float nearZ, float farZ)
{
    const float ral = right + left;
    const float rsl = right - left;
    const float tsb = top - bottom;
    const float tab = top + bottom;
    const float fan = farZ + nearZ;
    const float fsn = farZ - nearZ;
    GLKMatrix4 m = {
        2.0f * nearZ / rsl, 0.0f, 0.0f, 0.0f,
        0.0f, 2.0f * nearZ / tsb, 0.0f, 0.0f,
        ral / rsl, tab / tsb, -fan / fsn, -1.0f,
        0.0f, 0.0f, (-2.0f * farZ * nearZ) / fsn, 0.0f
    };
    return m;
}

static inline GLKVector4 GLKMatrix4MultiplyVector4(GLKMatrix4 matrixLeft, GLKVector4 vectorRight) {
#if defined(__ARM_NEON__)
    float32x4x4_t iMatrix = *(float32x4x4_t *)&matrixLeft;
    float32x4_t v;

    iMatrix.val[0] = vmulq_n_f32(iMatrix.val[0], (float32_t)vectorRight.v[0]);
    iMatrix.val[1] = vmulq_n_f32(iMatrix.val[1], (float32_t)vectorRight.v[1]);
    iMatrix.val[2] = vmulq_n_f32(iMatrix.val[2], (float32_t)vectorRight.v[2]);
    iMatrix.val[3] = vmulq_n_f32(iMatrix.val[3], (float32_t)vectorRight.v[3]);

    iMatrix.val[0] = vaddq_f32(iMatrix.val[0], iMatrix.val[1]);
    iMatrix.val[2] = vaddq_f32(iMatrix.val[2], iMatrix.val[3]);

    v = vaddq_f32(iMatrix.val[0], iMatrix.val[2]);

    return *(GLKVector4 *)&v;
#else
    GLKVector4 v = { matrixLeft.m[0] * vectorRight.v[0] + matrixLeft.m[4] * vectorRight.v[1] + matrixLeft.m[8] * vectorRight.v[2] + matrixLeft.m[12] * vectorRight.v[3],
                     matrixLeft.m[1] * vectorRight.v[0] + matrixLeft.m[5] * vectorRight.v[1] + matrixLeft.m[9] * vectorRight.v[2] + matrixLeft.m[13] * vectorRight.v[3],
                     matrixLeft.m[2] * vectorRight.v[0] + matrixLeft.m[6] * vectorRight.v[1] + matrixLeft.m[10] * vectorRight.v[2] + matrixLeft.m[14] * vectorRight.v[3],
                     matrixLeft.m[3] * vectorRight.v[0] + matrixLeft.m[7] * vectorRight.v[1] + matrixLeft.m[11] * vectorRight.v[2] + matrixLeft.m[15] * vectorRight.v[3] };
    return v;
#endif
}

static inline GLKVector3 GLKMatrix4MultiplyVector3WithTranslation(GLKMatrix4 matrixLeft, GLKVector3 vectorRight) {
    GLKVector4 v4 = GLKMatrix4MultiplyVector4(matrixLeft, GLKVector4Make(vectorRight.v[0], vectorRight.v[1], vectorRight.v[2], 1.0f));
    return GLKVector3Make(v4.v[0], v4.v[1], v4.v[2]);
}

static inline GLKVector3 GLKMatrix4MultiplyAndProjectVector3(GLKMatrix4 matrixLeft, GLKVector3 vectorRight) {
    GLKVector4 v4 = GLKMatrix4MultiplyVector4(matrixLeft, GLKVector4Make(vectorRight.v[0], vectorRight.v[1], vectorRight.v[2], 1.0f));
    return GLKVector3MultiplyScalar(GLKVector3Make(v4.v[0], v4.v[1], v4.v[2]), 1.0f / v4.v[3]);
}

static inline GLKVector4 GLKMatrix4GetRow(GLKMatrix4 matrix, int row) {
    GLKVector4 v = { matrix.m[row], matrix.m[4 + row], matrix.m[8 + row], matrix.m[12 + row] };
    return v;
}

static inline GLKVector4 GLKMatrix4GetColumn(GLKMatrix4 matrix, int column) {
#if defined(__ARM_NEON__)
    float32x4_t v = vld1q_f32(&(matrix.m[column * 4]));
    return *(GLKVector4 *)&v;
#else
    GLKVector4 v = { matrix.m[column * 4 + 0], matrix.m[column * 4 + 1], matrix.m[column * 4 + 2], matrix.m[column * 4 + 3] };
    return v;
#endif
}

static inline GLKMatrix4 GLKMatrix4MakeTranslation(float tx, float ty, float tz) {
    GLKMatrix4 m = GLKMatrix4Identity;
    m.m[12] = tx;
    m.m[13] = ty;
    m.m[14] = tz;
    return m;
}

static inline GLKMatrix4 GLKMatrix4MakeScale(float sx, float sy, float sz) {
    GLKMatrix4 m = GLKMatrix4Identity;
    m.m[0] = sx;
    m.m[5] = sy;
    m.m[10] = sz;
    return m;
}

static inline GLKMatrix4 GLKMatrix4MakeXRotation(float radians) {
    float cos = cosf(radians);
    float sin = sinf(radians);
    GLKMatrix4 m = { 1.0f, 0.0f, 0.0f, 0.0f,
                     0.0f, cos, sin, 0.0f,
                     0.0f, -sin, cos, 0.0f,
                     0.0f, 0.0f, 0.0f, 1.0f };
    return m;
}

static inline GLKMatrix4 GLKMatrix4MakeYRotation(float radians) {
    float cos = cosf(radians);
    float sin = sinf(radians);
    GLKMatrix4 m = { cos, 0.0f, -sin, 0.0f,
                     0.0f, 1.0f, 0.0f, 0.0f,
                     sin, 0.0f, cos, 0.0f,
                     0.0f, 0.0f, 0.0f, 1.0f };
    return m;
}

static inline GLKMatrix4 GLKMatrix4MakeZRotation(float radians) {
    float cos = cosf(radians);
    float sin = sinf(radians);
    GLKMatrix4 m = { cos, sin, 0.0f, 0.0f,
                     -sin, cos, 0.0f, 0.0f,
                     0.0f, 0.0f, 1.0f, 0.0f,
                     0.0f, 0.0f, 0.0f, 1.0f };
    return m;
}

static inline GLKMatrix4 GLKMatrix4MakeRotation(float radians, float x, float y, float z) {
    GLKVector3 v = GLKVector3Normalize(GLKVector3Make(x, y, z));
    float cos = cosf(radians);
    float cosp = 1.0f - cos;
    float sin = sinf(radians);

    GLKMatrix4 m = { cos + cosp * v.v[0] * v.v[0],
                     cosp * v.v[0] * v.v[1] + v.v[2] * sin,
                     cosp * v.v[0] * v.v[2] - v.v[1] * sin,
                     0.0f,
                     cosp * v.v[0] * v.v[1] - v.v[2] * sin,
                     cos + cosp * v.v[1] * v.v[1],
                     cosp * v.v[1] * v.v[2] + v.v[0] * sin,
                     0.0f,
                     cosp * v.v[0] * v.v[2] + v.v[1] * sin,
                     cosp * v.v[1] * v.v[2] - v.v[0] * sin,
                     cos + cosp * v.v[2] * v.v[2],
                     0.0f,
                     0.0f,
                     0.0f,
                     0.0f,
                     1.0f };

    return m;
}

static inline GLKMatrix4 GLKMatrix4Translate(GLKMatrix4 matrix, float tx, float ty, float tz) {
    GLKMatrix4 m = { matrix.m[0], matrix.m[1], matrix.m[2], matrix.m[3],
                     matrix.m[4], matrix.m[5], matrix.m[6], matrix.m[7],
                     matrix.m[8], matrix.m[9], matrix.m[10], matrix.m[11],
                     matrix.m[0] * tx + matrix.m[4] * ty + matrix.m[8] * tz + matrix.m[12],
                     matrix.m[1] * tx + matrix.m[5] * ty + matrix.m[9] * tz + matrix.m[13],
                     matrix.m[2] * tx + matrix.m[6] * ty + matrix.m[10] * tz + matrix.m[14],
                     matrix.m[3] * tx + matrix.m[7] * ty + matrix.m[11] * tz + matrix.m[15] };
    return m;
}

static inline GLKMatrix4 GLKMatrix4Scale(GLKMatrix4 matrix, float sx, float sy, float sz) {
#if defined(__ARM_NEON__)
    float32x4x4_t iMatrix = *(float32x4x4_t *)&matrix;
    float32x4x4_t m;

    m.val[0] = vmulq_n_f32(iMatrix.val[0], (float32_t)sx);
    m.val[1] = vmulq_n_f32(iMatrix.val[1], (float32_t)sy);
    m.val[2] = vmulq_n_f32(iMatrix.val[2], (float32_t)sz);
    m.val[3] = iMatrix.val[3];

    return *(GLKMatrix4 *)&m;
#else
    GLKMatrix4 m = { matrix.m[0] * sx, matrix.m[1] * sx, matrix.m[2] * sx, matrix.m[3] * sx,
                     matrix.m[4] * sy, matrix.m[5] * sy, matrix.m[6] * sy, matrix.m[7] * sy,
                     matrix.m[8] * sz, matrix.m[9] * sz, matrix.m[10] * sz, matrix.m[11] * sz,
                     matrix.m[12], matrix.m[13], matrix.m[14], matrix.m[15] };
    return m;
#endif
}

static inline GLKMatrix4 GLKMatrix4Rotate(GLKMatrix4 matrix, float radians, float x, float y, float z) {
    GLKMatrix4 rm = GLKMatrix4MakeRotation(radians, x, y, z);
    return GLKMatrix4Multiply(matrix, rm);
}

static inline GLKMatrix4 GLKMatrix4RotateX(GLKMatrix4 matrix, float radians) {
    GLKMatrix4 rm = GLKMatrix4MakeXRotation(radians);
    return GLKMatrix4Multiply(matrix, rm);
}

static inline GLKMatrix4 GLKMatrix4RotateY(GLKMatrix4 matrix, float radians) {
    GLKMatrix4 rm = GLKMatrix4MakeYRotation(radians);
    return GLKMatrix4Multiply(matrix, rm);
}

static inline GLKMatrix4 GLKMatrix4RotateZ(GLKMatrix4 matrix, float radians) {
    GLKMatrix4 rm = GLKMatrix4MakeZRotation(radians);
    return GLKMatrix4Multiply(matrix, rm);
}

static inline GLKMatrix4 GLKMatrix4MakeWithQuaternion(GLKQuaternion quaternion) {
    quaternion = GLKQuaternionNormalize(quaternion);

    float x = quaternion.q[0];
    float y = quaternion.q[1];
    float z = quaternion.q[2];
    float w = quaternion.q[3];

    float _2x = x + x;
    float _2y = y + y;
    float _2z = z + z;
    float _2w = w + w;

    GLKMatrix4 m = { 1.0f - _2y * y - _2z * z,
                     _2x * y + _2w * z,
                     _2x * z - _2w * y,
                     0.0f,
                     _2x * y - _2w * z,
                     1.0f - _2x * x - _2z * z,
                     _2y * z + _2w * x,
                     0.0f,
                     _2x * z + _2w * y,
                     _2y * z - _2w * x,
                     1.0f - _2x * x - _2y * y,
                     0.0f,
                     0.0f,
                     0.0f,
                     0.0f,
                     1.0f };

    return m;
}

static inline GLKVector3 GLKMatrix4MultiplyVector3(GLKMatrix4 matrixLeft, GLKVector3 vectorRight) {
    GLKVector4 v4 = GLKMatrix4MultiplyVector4(matrixLeft, GLKVector4Make(vectorRight.v[0], vectorRight.v[1], vectorRight.v[2], 0.0f));
    return GLKVector3Make(v4.v[0], v4.v[1], v4.v[2]);
}

static inline GLKQuaternion GLKQuaternionMakeWithMatrix4(GLKMatrix4 m4) {
    GLKMatrix3 m3 = {
        m4.m00, m4.m01, m4.m02,
        m4.m10, m4.m11, m4.m12,
        m4.m20, m4.m21, m4.m22,
    };
    return GLKQuaternionMakeWithMatrix3(m3);
}

#pragma clang diagnostic pop
