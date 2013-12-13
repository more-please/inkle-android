#pragma once

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreText/CoreText.h>

#import "UIColor.h"
#import "UIDevice.h"
#import "UIFont.h"

typedef enum UIViewAnimationOptions {
    UIViewAnimationOptionLayoutSubviews            = 1 <<  0,
    UIViewAnimationOptionAllowUserInteraction      = 1 <<  1, // turn on user interaction while animating
    UIViewAnimationOptionBeginFromCurrentState     = 1 <<  2, // start all views from current value, not initial value
    UIViewAnimationOptionRepeat                    = 1 <<  3, // repeat animation indefinitely
    UIViewAnimationOptionAutoreverse               = 1 <<  4, // if repeat, run animation back and forth
    UIViewAnimationOptionOverrideInheritedDuration = 1 <<  5, // ignore nested duration
    UIViewAnimationOptionOverrideInheritedCurve    = 1 <<  6, // ignore nested curve
    UIViewAnimationOptionAllowAnimatedContent      = 1 <<  7, // animate contents (applies to transitions only)
    UIViewAnimationOptionShowHideTransitionViews   = 1 <<  8, // flip to/from hidden state instead of adding/removing
    UIViewAnimationOptionOverrideInheritedOptions  = 1 <<  9, // do not inherit any options or animation type
    
//    UIViewAnimationOptionCurveEaseInOut            = 0 << 16, // default
//    UIViewAnimationOptionCurveEaseIn               = 1 << 16,
//    UIViewAnimationOptionCurveEaseOut              = 2 << 16,
//    UIViewAnimationOptionCurveLinear               = 3 << 16,
//    
//    UIViewAnimationOptionTransitionNone            = 0 << 20, // default
//    UIViewAnimationOptionTransitionFlipFromLeft    = 1 << 20,
//    UIViewAnimationOptionTransitionFlipFromRight   = 2 << 20,
//    UIViewAnimationOptionTransitionCurlUp          = 3 << 20,
//    UIViewAnimationOptionTransitionCurlDown        = 4 << 20,
//    UIViewAnimationOptionTransitionCrossDissolve   = 5 << 20,
//    UIViewAnimationOptionTransitionFlipFromTop     = 6 << 20,
//    UIViewAnimationOptionTransitionFlipFromBottom  = 7 << 20,
}
UIViewAnimationOptions;

typedef enum UIViewAutoresizing {
    UIViewAutoresizingNone                 = 0,
    UIViewAutoresizingFlexibleLeftMargin   = 1 << 0,
    UIViewAutoresizingFlexibleWidth        = 1 << 1,
    UIViewAutoresizingFlexibleRightMargin  = 1 << 2,
    UIViewAutoresizingFlexibleTopMargin    = 1 << 3,
    UIViewAutoresizingFlexibleHeight       = 1 << 4,
    UIViewAutoresizingFlexibleBottomMargin = 1 << 5
}
UIViewAutoresizing;

typedef enum UIViewContentMode {
    UIViewContentModeScaleToFill,
    UIViewContentModeScaleAspectFit,      // contents scaled to fit with fixed aspect. remainder is transparent
    UIViewContentModeScaleAspectFill,     // contents scaled to fill with fixed aspect. some portion of content may be clipped.
    UIViewContentModeRedraw,              // redraw on bounds change (calls -setNeedsDisplay)
    UIViewContentModeCenter,              // contents remain same size. positioned adjusted.
    UIViewContentModeTop,
    UIViewContentModeBottom,
    UIViewContentModeLeft,
    UIViewContentModeRight,
    UIViewContentModeTopLeft,
    UIViewContentModeTopRight,
    UIViewContentModeBottomLeft,
    UIViewContentModeBottomRight,
}
UIViewContentMode;

typedef enum UIActivityIndicatorViewStyle {
    UIActivityIndicatorViewStyleWhiteLarge,
    UIActivityIndicatorViewStyleWhite,
    UIActivityIndicatorViewStyleGray,
}
UIActivityIndicatorViewStyle;

typedef enum UIControlEvents {
    UIControlEventTouchDown           = 1 <<  0,      // on all touch downs
    UIControlEventTouchDownRepeat     = 1 <<  1,      // on multiple touchdowns (tap count > 1)
    UIControlEventTouchDragInside     = 1 <<  2,
    UIControlEventTouchDragOutside    = 1 <<  3,
    UIControlEventTouchDragEnter      = 1 <<  4,
    UIControlEventTouchDragExit       = 1 <<  5,
    UIControlEventTouchUpInside       = 1 <<  6,
    UIControlEventTouchUpOutside      = 1 <<  7,
    UIControlEventTouchCancel         = 1 <<  8,

    UIControlEventValueChanged        = 1 << 12,     // sliders, etc.

    UIControlEventEditingDidBegin     = 1 << 16,     // UITextField
    UIControlEventEditingChanged      = 1 << 17,
    UIControlEventEditingDidEnd       = 1 << 18,
    UIControlEventEditingDidEndOnExit = 1 << 19,     // 'return key' ending editing

    UIControlEventAllTouchEvents      = 0x00000FFF,  // for touch events
    UIControlEventAllEditingEvents    = 0x000F0000,  // for UITextField
    UIControlEventApplicationReserved = 0x0F000000,  // range available for application use
    UIControlEventSystemReserved      = 0xF0000000,  // range reserved for internal framework use
    UIControlEventAllEvents           = 0xFFFFFFFF
}
UIControlEvents;

typedef enum UIControlState {
    UIControlStateNormal       = 0,
    UIControlStateHighlighted  = 1 << 0,                  // used when UIControl isHighlighted is set
    UIControlStateDisabled     = 1 << 1,
//    UIControlStateSelected     = 1 << 2,                  // flag usable by app (see below)
//    UIControlStateApplication  = 0x00FF0000,              // additional flags available for application use
//    UIControlStateReserved     = 0xFF000000               // flags reserved for internal framework use
}
UIControlState;

typedef enum UIImageOrientation {
    UIImageOrientationUp,            // default orientation
    UIImageOrientationDown,          // 180 deg rotation
    UIImageOrientationLeft,          // 90 deg CCW
    UIImageOrientationRight,         // 90 deg CW
    UIImageOrientationUpMirrored,    // as above but image mirrored along other axis. horizontal flip
    UIImageOrientationDownMirrored,  // horizontal flip
    UIImageOrientationLeftMirrored,  // vertical flip
    UIImageOrientationRightMirrored, // vertical flip
}
UIImageOrientation;

typedef enum UIButtonType {
    UIButtonTypeCustom = 0,                         // no button type
//    UIButtonTypeSystem NS_ENUM_AVAILABLE_IOS(7_0),  // standard system button
//
//    UIButtonTypeDetailDisclosure,
//    UIButtonTypeInfoLight,
//    UIButtonTypeInfoDark,
//    UIButtonTypeContactAdd,
//    
//    UIButtonTypeRoundedRect = UIButtonTypeSystem,   // Deprecated, use UIButtonTypeSystem instead
}
UIButtonType;

typedef enum NSTextAlignment {
    NSTextAlignmentLeft      = 0,    // Visually left aligned
    NSTextAlignmentRight     = 1,    // Visually right aligned
    NSTextAlignmentCenter    = 2,    // Visually centered
    NSTextAlignmentJustified = 3,    // Fully-justified. The last line in a paragraph is natural-aligned.
    NSTextAlignmentNatural   = 4,    // Indicates the default alignment for script
}
NSTextAlignment;

typedef enum NSLineBreakMode {		/* What to do with long lines */
    NSLineBreakByWordWrapping = 0,     	/* Wrap at word boundaries, default */
    NSLineBreakByCharWrapping,		/* Wrap at character boundaries */
    NSLineBreakByClipping,		/* Simply clip */
    NSLineBreakByTruncatingHead,	/* Truncate at head of line: "...wxyz" */
    NSLineBreakByTruncatingTail,	/* Truncate at tail of line: "abcd..." */
    NSLineBreakByTruncatingMiddle	/* Truncate middle of line:  "ab...yz" */
}
NSLineBreakMode;

typedef struct UIEdgeInsets {
    CGFloat top, left, bottom, right;
} UIEdgeInsets;

typedef struct UIOffset {
    CGFloat horizontal, vertical;
} UIOffset;

extern const UIEdgeInsets UIEdgeInsetsZero;
extern const UIOffset UIOffsetZero;

static inline UIEdgeInsets UIEdgeInsetsMake(CGFloat top, CGFloat left, CGFloat bottom, CGFloat right) {
    UIEdgeInsets insets = {top, left, bottom, right};
    return insets;
}

static inline CGRect UIEdgeInsetsInsetRect(CGRect rect, UIEdgeInsets insets) {
    rect.origin.x    += insets.left;
    rect.origin.y    += insets.top;
    rect.size.width  -= (insets.left + insets.right);
    rect.size.height -= (insets.top  + insets.bottom);
    return rect;
}

@interface UIGestureRecognizer : NSObject
@end

extern NSString* const UIApplicationDidReceiveMemoryWarningNotification;

extern CTTextAlignment NSTextAlignmentToCTTextAlignment(NSTextAlignment nsTextAlignment);