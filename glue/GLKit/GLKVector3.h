#pragma once

#import <CoreGraphics/CoreGraphics.h>

union _GLKVector3
{
    struct { float x, y, z; };
    struct { float r, g, b; };
    struct { float s, t, p; };
    float v[3];
};
typedef union _GLKVector3 GLKVector3;


static inline GLKVector3 GLKVector3Make(float x, float y, float z) {
    GLKVector3 v = { x, y, z };
    return v;
}

static inline GLKVector3 GLKVector3MakeWithArray(float values[3]) {
    GLKVector3 v = { values[0], values[1], values[2] };
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

static inline GLKVector3 GLKVector3Add(GLKVector3 vectorLeft, GLKVector3 vectorRight) {
    GLKVector3 v = {
        vectorLeft.v[0] + vectorRight.v[0],
        vectorLeft.v[1] + vectorRight.v[1],
        vectorLeft.v[2] + vectorRight.v[2]
    };
    return v;
}

static inline GLKVector3 GLKVector3Subtract(GLKVector3 vectorLeft, GLKVector3 vectorRight) {
    GLKVector3 v = {
        vectorLeft.v[0] - vectorRight.v[0],
        vectorLeft.v[1] - vectorRight.v[1],
        vectorLeft.v[2] - vectorRight.v[2]
    };
    return v;
}

static inline GLKVector3 GLKVector3Multiply(GLKVector3 vectorLeft, GLKVector3 vectorRight) {
    GLKVector3 v = {
        vectorLeft.v[0] * vectorRight.v[0],
        vectorLeft.v[1] * vectorRight.v[1],
        vectorLeft.v[2] * vectorRight.v[2]
    };
    return v;
}

static inline GLKVector3 GLKVector3Divide(GLKVector3 vectorLeft, GLKVector3 vectorRight) {
    GLKVector3 v = {
        vectorLeft.v[0] / vectorRight.v[0],
        vectorLeft.v[1] / vectorRight.v[1],
        vectorLeft.v[2] / vectorRight.v[2]
    };
    return v;
}

static inline GLKVector3 GLKVector3AddScalar(GLKVector3 vector, float value) {
    GLKVector3 v = {
        vector.v[0] + value,
        vector.v[1] + value,
        vector.v[2] + value
    };
    return v;
}

static inline GLKVector3 GLKVector3SubtractScalar(GLKVector3 vector, float value) {
    GLKVector3 v = {
        vector.v[0] - value,
        vector.v[1] - value,
        vector.v[2] - value
    };
    return v;
}

static inline GLKVector3 GLKVector3MultiplyScalar(GLKVector3 vector, float value) {
    GLKVector3 v = {
        vector.v[0] * value,
        vector.v[1] * value,
        vector.v[2] * value
    };
    return v;
}

static inline GLKVector3 GLKVector3DivideScalar(GLKVector3 vector, float value) {
    GLKVector3 v = {
        vector.v[0] / value,
        vector.v[1] / value,
        vector.v[2] / value
    };
    return v;
}

static inline float GLKVector3Distance(GLKVector3 vectorStart, GLKVector3 vectorEnd) {
    return GLKVector3Length(GLKVector3Subtract(vectorEnd, vectorStart));
}
    
static inline GLKVector3 GLKVector3Lerp(GLKVector3 vectorStart, GLKVector3 vectorEnd, float t) {
    GLKVector3 v = {
        vectorStart.v[0] + ((vectorEnd.v[0] - vectorStart.v[0]) * t),
        vectorStart.v[1] + ((vectorEnd.v[1] - vectorStart.v[1]) * t),
        vectorStart.v[2] + ((vectorEnd.v[2] - vectorStart.v[2]) * t)
    };
    return v;
}
