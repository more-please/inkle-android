#pragma once

#import <Foundation/Foundation.h>

typedef enum CTTextAlignment {
    kCTTextAlignmentLeft = 0,
    kCTTextAlignmentRight = 1,
    kCTTextAlignmentCenter = 2,
    kCTTextAlignmentJustified = 3,
    kCTTextAlignmentNatural = 4,

    kCTLeftTextAlignment = kCTTextAlignmentLeft,
    kCTRightTextAlignment = kCTTextAlignmentRight,
    kCTCenterTextAlignment = kCTTextAlignmentCenter,
    kCTJustifiedTextAlignment = kCTTextAlignmentJustified,
    kCTNaturalTextAlignment = kCTTextAlignmentNatural
}
CTTextAlignment;

typedef enum CTLineBreakMode {
    kCTLineBreakByWordWrapping = 0,
    kCTLineBreakByCharWrapping = 1,
    kCTLineBreakByClipping = 2,
    kCTLineBreakByTruncatingHead = 3,
    kCTLineBreakByTruncatingTail = 4,
    kCTLineBreakByTruncatingMiddle = 5
}
CTLineBreakMode;

typedef enum CTWritingDirection {
    kCTWritingDirectionNatural = -1,
    kCTWritingDirectionLeftToRight = 0,
    kCTWritingDirectionRightToLeft = 1
}
CTWritingDirection;

typedef enum CTParagraphStyleSpecifier {
    kCTParagraphStyleSpecifierAlignment = 0,
    kCTParagraphStyleSpecifierFirstLineHeadIndent = 1,
    kCTParagraphStyleSpecifierHeadIndent = 2,
    kCTParagraphStyleSpecifierTailIndent = 3,
    kCTParagraphStyleSpecifierTabStops = 4,
    kCTParagraphStyleSpecifierDefaultTabInterval = 5,
    kCTParagraphStyleSpecifierLineBreakMode = 6,
    kCTParagraphStyleSpecifierLineHeightMultiple = 7,
    kCTParagraphStyleSpecifierMaximumLineHeight = 8,
    kCTParagraphStyleSpecifierMinimumLineHeight = 9,
    kCTParagraphStyleSpecifierLineSpacing = 10,			/* deprecated */
    kCTParagraphStyleSpecifierParagraphSpacing = 11,
    kCTParagraphStyleSpecifierParagraphSpacingBefore = 12,
    kCTParagraphStyleSpecifierBaseWritingDirection = 13,
    kCTParagraphStyleSpecifierMaximumLineSpacing = 14,
    kCTParagraphStyleSpecifierMinimumLineSpacing = 15,
    kCTParagraphStyleSpecifierLineSpacingAdjustment = 16,
    kCTParagraphStyleSpecifierLineBoundsOptions = 17,

    kCTParagraphStyleSpecifierCount
}
CTParagraphStyleSpecifier;

// iOS distinguishes between NSString and CFStr but we don't have to.
#define kCTFontAttributeName NSFontAttributeName
