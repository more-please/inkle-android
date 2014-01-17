#import "UIKit.h"

const UIEdgeInsets UIEdgeInsetsZero = {0, 0};
const UIOffset UIOffsetZero = {0, 0};

NSString* const UIApplicationDidReceiveMemoryWarningNotification = @"UIApplicationDidReceiveMemoryWarningNotification";

NSString* const UIPageViewControllerOptionSpineLocationKey = @"spineLocation";

UIEdgeInsets UIEdgeInsetsFromString(NSString* string) {
    NSLog(@"UIEdgeInsetsFromString(%@) not implemented!", string);
    return UIEdgeInsetsZero;
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
