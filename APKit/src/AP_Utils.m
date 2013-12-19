#import "AP_Utils.h"

#import "AP_Log.h"

#ifndef ANDROID
GLKVector4 AP_ColorToVector(UIColor* color) {
    CGFloat r, g, b, a;
    CGColorRef colorRef = color.CGColor;
    const CGFloat* c = CGColorGetComponents(colorRef);
    size_t numComponents = CGColorGetNumberOfComponents(colorRef);
    switch (numComponents) {
        case 0:
            r = g = b = a = 0;
            break;
        case 1:
            r = g = b = c[0];
            a = 1;
            break;
        case 2:
            r = g = b = c[0];
            a = c[1];
            break;
        case 3:
            r = c[0];
            g = c[1];
            b = c[2];
            a = 1;
            break;
        case 4:
            r = c[0];
            g = c[1];
            b = c[2];
            a = c[3];
            break;
        default:
            AP_LogError("Unexpected result from CGColorGetComponents!");
            r = g = b = a = 0;
            break;
    }
    return GLKVector4Make(r, g, b, a);
}

UIColor* AP_VectorToColor(GLKVector4 rgba) {
    return [UIColor colorWithRed:rgba.r green:rgba.g blue:rgba.b alpha:rgba.a];
}
#endif
