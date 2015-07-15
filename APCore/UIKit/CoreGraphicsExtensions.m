#import "CoreGraphicsExtensions.h"

CGPoint CGPointFromString(NSString* s) {
    if (!s) {
        NSLog(@"*** null input to CGPointFromString");
        return CGPointZero;
    }
    if (![s isKindOfClass:NSString.class]) {
        NSLog(@"*** CGPointFromString expected String but received: %@", s);
        return CGPointZero;
    }
    NSPoint ns = NSPointFromString(s);
    CGPoint cg = { ns.x, ns.y };
    return cg;
}

NSString* NSStringFromCGPoint(CGPoint p) {
    NSPoint ns = {p.x, p.y};
    return NSStringFromPoint(ns);
}

CGRect CGRectFromString(NSString* s) {
    NSRect ns = NSRectFromString(s);
    CGRect r = {{ns.origin.x, ns.origin.y}, {ns.size.width, ns.size.height}};
    return r;
}

NSString* NSStringFromCGRect(CGRect r) {
    NSRect ns = {{r.origin.x, r.origin.y}, {r.size.width, r.size.height}};
    return NSStringFromRect(ns);
}
