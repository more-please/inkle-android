#import "UIKit.h"

#import <Foundation/NSGeometry.h>

const UIEdgeInsets UIEdgeInsetsZero = {0, 0};
const UIOffset UIOffsetZero = {0, 0};

NSString* const UIApplicationDidReceiveMemoryWarningNotification = @"UIApplicationDidReceiveMemoryWarningNotification";
NSString* const UIKeyboardWillShowNotification = @"UIKeyboardWillShowNotification";
NSString* const UIKeyboardWillHideNotification = @"UIKeyboardWillHideNotification";
NSString* const UIKeyboardAnimationDurationUserInfoKey = @"UIKeyboardAnimationDurationUserInfoKey";
NSString* const UIKeyboardAnimationCurveUserInfoKey = @"UIKeyboardAnimationCurveUserInfoKey";

NSString* const UIPageViewControllerOptionSpineLocationKey = @"spineLocation";

UIEdgeInsets UIEdgeInsetsFromString(NSString* s) {
    // Cheap hack... parse it as a Rect and hope it doesn't have parameter names!
    NSRect ns = NSRectFromString(s);
    UIEdgeInsets insets = { ns.origin.x, ns.origin.y, ns.size.width, ns.size.height };
    return insets;
}

CTTextAlignment NSTextAlignmentToCTTextAlignment(NSTextAlignment nsTextAlignment) {
    switch (nsTextAlignment) {
        case NSTextAlignmentLeft:
            return kCTTextAlignmentLeft;
        case NSTextAlignmentCenter:
            return kCTTextAlignmentCenter;
        case NSTextAlignmentJustified:
            return kCTTextAlignmentJustified;
        case NSTextAlignmentRight:
            return kCTTextAlignmentRight;
        case NSTextAlignmentNatural:
            return kCTTextAlignmentNatural;
        default:
            NSLog(@"Unexpected NSTextAlignment: %d", nsTextAlignment);
            return kCTTextAlignmentNatural;
    }
}
