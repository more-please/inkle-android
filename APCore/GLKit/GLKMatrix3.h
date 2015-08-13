#pragma once

#import <CoreGraphics/CoreGraphics.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmissing-braces"

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

extern const GLKMatrix3 GLKMatrix3Identity;

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

#pragma clang diagnostic pop
