#pragma once

#import <CoreGraphics/CoreGraphics.h>

union _GLKVector2 {
    struct { float x, y; };
    struct { float s, t; };
    float v[2];
} __attribute__((aligned(8)));
typedef union _GLKVector2 GLKVector2;

static inline GLKVector2 GLKVector2Make(float x, float y) {
    GLKVector2 v = { x, y };
    return v;
}

static inline float GLKVector2Length(GLKVector2 vector) {
#if defined(__ARM_NEON__)
    float32x2_t v = vmul_f32(*(float32x2_t *)&vector,
                             *(float32x2_t *)&vector);
    v = vpadd_f32(v, v);
    return sqrt(vget_lane_f32(v, 0)); 
#else
    return sqrt(vector.v[0] * vector.v[0] + vector.v[1] * vector.v[1]);
#endif
}

static inline GLKVector2 GLKVector2Negate(GLKVector2 vector) {
#if defined(__ARM_NEON__)
    float32x2_t v = vneg_f32(*(float32x2_t *)&vector);
    return *(GLKVector2 *)&v;
#else
    GLKVector2 v = { -vector.v[0] , -vector.v[1] };
    return v;
#endif
}
 
static inline GLKVector2 GLKVector2Add(GLKVector2 vectorLeft, GLKVector2 vectorRight) {
#if defined(__ARM_NEON__)
    float32x2_t v = vadd_f32(*(float32x2_t *)&vectorLeft,
                             *(float32x2_t *)&vectorRight);
    return *(GLKVector2 *)&v;
#else
    GLKVector2 v = { vectorLeft.v[0] + vectorRight.v[0],
                     vectorLeft.v[1] + vectorRight.v[1] };
    return v;
#endif
}
  
static inline GLKVector2 GLKVector2Subtract(GLKVector2 vectorLeft, GLKVector2 vectorRight) {
#if defined(__ARM_NEON__)
    float32x2_t v = vsub_f32(*(float32x2_t *)&vectorLeft,
                             *(float32x2_t *)&vectorRight);
    return *(GLKVector2 *)&v;
#else
    GLKVector2 v = { vectorLeft.v[0] - vectorRight.v[0],
                     vectorLeft.v[1] - vectorRight.v[1] };
    return v;
#endif
}
    
static inline GLKVector2 GLKVector2Multiply(GLKVector2 vectorLeft, GLKVector2 vectorRight) {
#if defined(__ARM_NEON__)
    float32x2_t v = vmul_f32(*(float32x2_t *)&vectorLeft,
                             *(float32x2_t *)&vectorRight);
    return *(GLKVector2 *)&v;
#else
    GLKVector2 v = { vectorLeft.v[0] * vectorRight.v[0],
                     vectorLeft.v[1] * vectorRight.v[1] };
    return v;
#endif
}
    
static inline GLKVector2 GLKVector2Divide(GLKVector2 vectorLeft, GLKVector2 vectorRight) {
#if defined(__ARM_NEON__)
    float32x2_t *vLeft = (float32x2_t *)&vectorLeft;
    float32x2_t *vRight = (float32x2_t *)&vectorRight;
    float32x2_t estimate = vrecpe_f32(*vRight);    
    estimate = vmul_f32(vrecps_f32(*vRight, estimate), estimate);
    estimate = vmul_f32(vrecps_f32(*vRight, estimate), estimate);
    float32x2_t v = vmul_f32(*vLeft, estimate);
    return *(GLKVector2 *)&v;
#else
    GLKVector2 v = { vectorLeft.v[0] / vectorRight.v[0],
                     vectorLeft.v[1] / vectorRight.v[1] };
    return v;
#endif
}

static inline GLKVector2 GLKVector2AddScalar(GLKVector2 vector, float value) {
#if defined(__ARM_NEON__)
    float32x2_t v = vadd_f32(*(float32x2_t *)&vector,
                             vdup_n_f32((float32_t)value));
    return *(GLKVector2 *)&v;
#else
    GLKVector2 v = { vector.v[0] + value,
                     vector.v[1] + value };
    return v;
#endif
}
    
static inline GLKVector2 GLKVector2SubtractScalar(GLKVector2 vector, float value) {
#if defined(__ARM_NEON__)
    float32x2_t v = vsub_f32(*(float32x2_t *)&vector,
                             vdup_n_f32((float32_t)value));
    return *(GLKVector2 *)&v;
#else
    GLKVector2 v = { vector.v[0] - value,
                     vector.v[1] - value };
    return v;
#endif
}
    
static inline GLKVector2 GLKVector2MultiplyScalar(GLKVector2 vector, float value) {
#if defined(__ARM_NEON__)
    float32x2_t v = vmul_f32(*(float32x2_t *)&vector,
                             vdup_n_f32((float32_t)value));
    return *(GLKVector2 *)&v;
#elif defined(GLK_SSE3_INTRINSICS)
    __m128 v;
    v = _mm_mul_ps(_mm_loadl_pi(_mm_setzero_ps(), (__m64 *)&vector), _mm_set1_ps(value));
    return *(GLKVector2 *)&v;
#else
    GLKVector2 v = { vector.v[0] * value,
                     vector.v[1] * value };
    return v;
#endif
}
    
static inline GLKVector2 GLKVector2DivideScalar(GLKVector2 vector, float value) {
#if defined(__ARM_NEON__)
    float32x2_t values = vdup_n_f32((float32_t)value);
    float32x2_t estimate = vrecpe_f32(values);    
    estimate = vmul_f32(vrecps_f32(values, estimate), estimate);
    estimate = vmul_f32(vrecps_f32(values, estimate), estimate);
    float32x2_t v = vmul_f32(*(float32x2_t *)&vector, estimate);
    return *(GLKVector2 *)&v;
#else
    GLKVector2 v = { vector.v[0] / value,
                     vector.v[1] / value };
    return v;
#endif
}

static inline GLKVector2 GLKVector2Normalize(GLKVector2 vector) {
    float scale = 1.0f / GLKVector2Length(vector);
    GLKVector2 v = GLKVector2MultiplyScalar(vector, scale);
    return v;
}