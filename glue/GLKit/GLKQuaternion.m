#import "GLKQuaternion.h"

const GLKQuaternion GLKQuaternionIdentity = {
    0.0f, 0.0f, 0.0f, 1.0f
};

// Taken from: http://www.cg.info.hiroshima-cu.ac.jp/~miyazaki/knowledge/teche52.html
// Might need transposition!

static inline float SIGN(float x) {return (x >= 0.0f) ? +1.0f : -1.0f;}
static inline float NORM(float a, float b, float c, float d) {return sqrt(a * a + b * b + c * c + d * d);}

GLKQuaternion GLKQuaternionMakeWithMatrix3(GLKMatrix3 m) {
    float r11 = m.m00;
    float r12 = m.m01;
    float r13 = m.m02;
    float r21 = m.m10;
    float r22 = m.m11;
    float r23 = m.m12;
    float r31 = m.m20;
    float r32 = m.m21;
    float r33 = m.m22;
    float q0, q1, q2, q3, r;

    q0 = ( r11 + r22 + r33 + 1.0f) / 4.0f;
    q1 = ( r11 - r22 - r33 + 1.0f) / 4.0f;
    q2 = (-r11 + r22 - r33 + 1.0f) / 4.0f;
    q3 = (-r11 - r22 + r33 + 1.0f) / 4.0f;
    if(q0 < 0.0f) q0 = 0.0f;
    if(q1 < 0.0f) q1 = 0.0f;
    if(q2 < 0.0f) q2 = 0.0f;
    if(q3 < 0.0f) q3 = 0.0f;
    q0 = sqrt(q0);
    q1 = sqrt(q1);
    q2 = sqrt(q2);
    q3 = sqrt(q3);
    if(q0 >= q1 && q0 >= q2 && q0 >= q3) {
        q0 *= +1.0f;
        q1 *= SIGN(r32 - r23);
        q2 *= SIGN(r13 - r31);
        q3 *= SIGN(r21 - r12);
    } else if(q1 >= q0 && q1 >= q2 && q1 >= q3) {
        q0 *= SIGN(r32 - r23);
        q1 *= +1.0f;
        q2 *= SIGN(r21 + r12);
        q3 *= SIGN(r13 + r31);
    } else if(q2 >= q0 && q2 >= q1 && q2 >= q3) {
        q0 *= SIGN(r13 - r31);
        q1 *= SIGN(r21 + r12);
        q2 *= +1.0f;
        q3 *= SIGN(r32 + r23);
    } else if(q3 >= q0 && q3 >= q1 && q3 >= q2) {
        q0 *= SIGN(r21 - r12);
        q1 *= SIGN(r31 + r13);
        q2 *= SIGN(r32 + r23);
        q3 *= +1.0f;
    } else {
        NSLog(@"GLKQuaternionMakeWithMatrix3 - coding error");
    }
    r = NORM(q0, q1, q2, q3);
    q0 /= r;
    q1 /= r;
    q2 /= r;
    q3 /= r;

    return GLKQuaternionMake(q0, q1, q2, q3);
}
