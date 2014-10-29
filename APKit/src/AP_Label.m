#import "AP_Label.h"

#import <UIKit/UIKit.h>

#import "INKAttributedStringParagraphStyle.h"
#import "NSAttributedString+Attributes.h"

#import "AP_Application.h"
#import "AP_Check.h"
#import "AP_GLBuffer.h"
#import "AP_GLProgram.h"
#import "AP_GLTexture.h"
#import "AP_Touch.h"
#import "AP_Utils.h"

@implementation AP_Label {
    NSMutableAttributedString* _text;

    // Properties applied to non-attributed text.
    AP_Font* _font;
    NSTextAlignment _alignment;
    CGFloat _lineSpacing;
    UIColor* _textColor;
    UIColor* _shadowColor;
    CGSize _shadowOffset;

    CGFloat _layoutWidth;
    BOOL _atStartOfParagraph;
    BOOL _atStartOfLine;
    CGPoint _cursor;
    NSMutableArray* _formattedRuns;
    NSMutableArray* _currentLineRuns;
    INKAttributedStringParagraphStyle* _currentStyle;
    CGSize _formattedSize;
    int _formattedLineCount;

    NSMutableArray* _urlRuns;

    AP_Font_Run* _hitTestRun;
    BOOL _hitTestInside;

    CGFloat _fontScale; // Default 1.0, reduced if needed by adjustsFontSizeToFitWidth
}

- (void) labelCommonInit
{
    self.userInteractionEnabled = NO;

    _text = [NSMutableAttributedString attributedStringWithString:@""];
    _font = [AP_Font systemFontOfSize:17];
    _alignment = NSTextAlignmentNatural;
    _lineSpacing = 0;
    _textColor = [UIColor blackColor];
    _shadowColor = [UIColor clearColor];
    _shadowOffset = CGSizeMake(0, -1);

    _urlRuns = [NSMutableArray array];

    _numberOfLines = 1;

    _fontScale = 1.0;
}

- (id) init
{
    self = [super init];
    if (self) {
        [self labelCommonInit];
    }
    return self;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self labelCommonInit];
    }
    return self;
}

- (BOOL) isUserInteractionEnabled
{
    if (_urlRuns.count > 0) {
        return YES;
    } else {
        return [super isUserInteractionEnabled];
    }
}

- (void) touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event
{
    if (!_hitTestRun) {
        for (AP_Touch* t in touches) {
            CGPoint p = [t locationInView:self];
            for (AP_Font_Run* run in _urlRuns) {
                CGRect r = run.frame;
                if (CGRectContainsPoint(r, p)) {
                    _hitTestRun = run;
                    _hitTestInside = YES;
                    break;
                }
            }
        }
    }

    if (!_hitTestRun) {
        // Try again with a larger hit rect.
        for (AP_Touch* t in touches) {
            CGPoint p = [t locationInView:self];
            for (AP_Font_Run* run in _urlRuns) {
                CGRect r = run.frame;
                CGRectInset(r, -6, -12);
                if (CGRectContainsPoint(run.frame, p)) {
                    _hitTestRun = run;
                    _hitTestInside = YES;
                    break;
                }
            }
        }
    }
}

- (void) touchesMoved:(NSSet*)touches withEvent:(AP_Event*)event
{
    if (_hitTestRun) {
        CGRect r = _hitTestRun.frame;
        CGRectInset(r, -6, -12);

        _hitTestInside = YES;
        for (AP_Touch* t in event.allTouches) {
            CGPoint p = [t locationInView:self];
            if (!CGRectContainsPoint(r, p)) {
                _hitTestInside = NO;
            }
        }
    }
}

- (void) touchesEnded:(NSSet*)touches withEvent:(AP_Event*)event
{
    if (_hitTestRun) {
        CGRect r = _hitTestRun.frame;
        CGRectInset(r, -6, -12);

        _hitTestInside = YES;
        for (AP_Touch* t in event.allTouches) {
            CGPoint p = [t locationInView:self];
            if (!CGRectContainsPoint(r, p)) {
                _hitTestInside = NO;
            }
        }

        if (_hitTestInside) {
            NSURL* url = [NSURL URLWithString:_hitTestRun.url];
            [[AP_Application sharedApplication] openURL:url];
        }
    }
    _hitTestRun = nil;
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(AP_Event *)event
{
    _hitTestRun = nil;
}

- (NSAttributedString*) attributedText
{
    return [_text copy];
}

- (CGSize) sizeThatFits:(CGSize)size
{
    [self textLayoutWithWidth:size.width];
    while (_numberOfLines > 0 && _formattedLineCount > _numberOfLines && _formattedSize.width > 0) {
        size.width = MAX(size.width, _formattedSize.width) * 1.1;
        [self textLayoutWithWidth:size.width];
    }
    return _formattedSize;
}

- (void) setAttributedText:(NSAttributedString *)attributedText
{
    AP_CHECK(attributedText, return);
    _text = [attributedText mutableCopy];
    [self setNeedsTextLayout];
}

- (NSString*) text
{
    return [_text string];
}

- (void) setText:(NSString *)text
{
    if (!text) {
        // This often happens with textless buttons... Should the text be nil or empty?
        text = @"";
    }
    // Assume that if the text isn't styled, we want to center vertically like UILabel does.
    _centerVertically = YES;
    _text = [NSMutableAttributedString attributedStringWithString:text];
    [_text setFont:_font];
    [_text setTextColor:_textColor];
    [_text setTextAlignment:NSTextAlignmentToCTTextAlignment(_alignment)];
    [_text setLineSpacingAdjustment:_lineSpacing];
    [self setNeedsTextLayout];
}

- (AP_Font*) font
{
    if (_text.length > 0) {
        return [_text attribute:kINKAttributedStringFontAttribute atIndex:0 effectiveRange:NULL];
    } else {
        return _font;
    }
}

- (void) setFont:(AP_Font*)font
{
    _font = font;
    [_text setFont:font];
    [self setNeedsTextLayout];
}

- (UIColor*) textColor
{
    if (_text.length > 0) {
        return [_text attribute:kINKAttributedStringColorAttribute atIndex:0 effectiveRange:NULL];
    } else {
        return _textColor;
    }
}

- (void) setTextColor:(UIColor*)color
{
    _textColor = color;
    [_text setTextColor:color];
    [self setNeedsTextLayout];
}

- (void) setTextAlignment:(NSTextAlignment)alignment
{
    _alignment = alignment;
    [_text setTextAlignment:NSTextAlignmentToCTTextAlignment(alignment)];
    [self setNeedsTextLayout];
}

- (void) setLineSpacingAdjustment:(CGFloat)adjustment
{
    _lineSpacing = adjustment;
    [_text setLineSpacingAdjustment:adjustment];
    [self setNeedsTextLayout];
}

- (void) setShadowColor:(UIColor*)color
{
    _shadowColor = color;
}

- (void) setShadowOffset:(CGSize)offset
{
    _shadowOffset = offset;
}

- (void) setLineBreakMode:(NSLineBreakMode)mode
{
    // Do we really use anything other than word-wrapping?
    // To implement, blow away and recreate the font runs, I guess.
    AP_CHECK(mode == NSLineBreakByWordWrapping, return);
}

- (void) finishCurrentLine
{
    if (!_atStartOfLine) {
        _formattedSize.width = MAX(_formattedSize.width, _cursor.x - _currentStyle.tailIndent);

        CGPoint offset;
        
        // Calculate x offset based on line length and alignment.
        CGFloat xGap = (_layoutWidth + _currentStyle.tailIndent) - _cursor.x;
        switch (_currentStyle.alignment) {
            case kCTTextAlignmentRight:
                offset.x = xGap;
                break;

            case kCTTextAlignmentCenter:
                offset.x = xGap / 2;
                break;

            case kCTTextAlignmentJustified:
                AP_NOT_IMPLEMENTED;
                // fall through
            case kCTTextAlignmentLeft:
            case kCTTextAlignmentNatural:
            default:
                offset.x = 0;
                break;
        }

        // Calculate y adjustment based on maximum ascent and line height.
        CGFloat maxAscent = 0;
        CGFloat maxLineHeight = 0;
        CGFloat lineSpacing = _currentStyle.lineSpacingAdjustment;
        for (AP_Font_Run* run in _currentLineRuns) {
            maxAscent = MAX(maxAscent, run.ascender);
            maxLineHeight = MAX(maxLineHeight, run.size.height);
        }
        offset.y = maxAscent + lineSpacing / 2;

        // Apply adjustments and mark the current line as formatted.
        for (AP_Font_Run* run in _currentLineRuns) {
            CGPoint p = run.origin;
            p.x += offset.x;
            p.y += offset.y;
            run.origin = p;
        }
        [_formattedRuns addObjectsFromArray:_currentLineRuns];
        _currentLineRuns = [NSMutableArray array];

        // Get ready for the next line.
        _cursor.x = 0;
        _cursor.y += maxLineHeight + lineSpacing;
        _atStartOfLine = YES;

        _formattedSize.height = _cursor.y;
        ++_formattedLineCount;
    }
}

- (void) setNeedsTextLayout
{
    _formattedRuns = nil;
}

- (void) textLayoutWithWidth:(CGFloat)width
{
    if (_formattedRuns && _layoutWidth == width) {
        return;
    }

    _fontScale = 1.0;
    [self scaledTextLayoutWithWidth:width];

    if (_adjustsFontSizeToFitWidth && _formattedSize.width > width) {
        _fontScale = MAX(0.1, width / _formattedSize.width);
        [self scaledTextLayoutWithWidth:width];
    }
}

- (void) scaledTextLayoutWithWidth:(CGFloat)width
{
    NSString* str = [_text string];

    INKAttributedStringParagraphStyle* defaultStyle = [INKAttributedStringParagraphStyle style];
    AP_Font* defaultFont = [AP_Font systemFontOfSize:17];
    UIColor* defaultColor = [UIColor blackColor];

    _layoutWidth = width;
    _formattedRuns = [NSMutableArray array];
    _currentLineRuns = [NSMutableArray array];
    _currentStyle = defaultStyle;
    _atStartOfParagraph = _atStartOfLine = YES;
    _cursor = CGPointZero;
    _formattedSize = CGSizeZero;
    _formattedLineCount = 0;

    [_text enumerateAttributesInRange:NSMakeRange(0, [_text length]) options:0 usingBlock:^(NSDictionary* attrs, NSRange range, BOOL* stop) {

        // Get the font, color and paragraph style.
        AP_Font* font = [attrs objectForKey:kINKAttributedStringFontAttribute];
        if (!font) {
            font = defaultFont;
        }
        font = [font fontWithSize:(font.pointSize * _fontScale)];

        UIColor* color = [attrs objectForKey:kINKAttributedStringColorAttribute];
        if (!color) {
            color = defaultColor;
        }
        _currentStyle = [attrs objectForKey:kINKAttributedStringParagraphStyleAttribute];
        if (!_currentStyle) {
            _currentStyle = defaultStyle;
        }
        NSString* url = [attrs objectForKey:kINKAttributedStringUrlAttribute];

        // Parse the characters.
        NSString* chars = [str substringWithRange:range];
        AP_Font_Run* run = [font runForString:chars];
        run.textColor = color;
        run.image = [attrs objectForKey:kINKAttributedStringImageAttribute];

        // Split at paragraph breaks, handle each paragraph separately.
        while (run.numChars > 0) {
            AP_Font_Run* nextParagraph;
            run = [run splitAtLineBreakLeaving:&nextParagraph];

            // Word-wrap as necessary.
            while (run.numChars > 0) {
                if (_atStartOfParagraph) {
                    _cursor.y += _currentStyle.paragraphSpacingBefore;
                    _cursor.x += _currentStyle.firstLineHeadIndent;
                } else if (_atStartOfLine) {
                    _cursor.x += _currentStyle.headIndent;
                }

                AP_Font_Run* nextLine;
                if (_numberOfLines != 1) {
                    AP_Font_Run* line = [run splitAtWidth:(_layoutWidth + _currentStyle.tailIndent - _cursor.x) leaving:&nextLine];
                    if (line.numChars == 0 && _atStartOfLine) {
                        // Just split at the first place we can.
                        line = [run splitAtWordBreakLeaving:&nextLine];
                    }
                    run = line;
                }
                run.url = url;

                if (run.numChars > 0) {
                    run.origin = _cursor;
                    _cursor.x += run.size.width;
                    [_currentLineRuns addObject:run];
                } else if (_atStartOfLine) {
                    AP_LogError("Can't fit anything into the current line!");
                    break;
                }

                _atStartOfLine = _atStartOfParagraph = NO;
                if (!nextLine) {
                    break;
                }
                [self finishCurrentLine];
                run = nextLine;
            }

            if (!nextParagraph) {
                break;
            }

            [self finishCurrentLine];

            _atStartOfParagraph = YES;
            _cursor.y += _currentStyle.paragraphSpacing;
            run = nextParagraph;
        }
    }];

    [self finishCurrentLine];

    _urlRuns = [NSMutableArray array];
    for (AP_Font_Run* run in _formattedRuns) {
        if (run.url) {
            [_urlRuns addObject:run];
        }
    }
}

- (void) renderWithBoundsToGL:(CGAffineTransform)boundsToGL alpha:(CGFloat)alpha
{
    CGRect bounds = self.bounds;
//    if (bounds.size.width > 0) {
//        self.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.5];
//    } else {
//        self.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.5];
//    }

    [super renderWithBoundsToGL:boundsToGL alpha:alpha];

    [self textLayoutWithWidth:bounds.size.width];
    AP_CHECK(_formattedRuns, return);

    if (_centerVertically || _numberOfLines == 1) {
        CGFloat yGap = bounds.size.height - _formattedSize.height;
        boundsToGL = CGAffineTransformTranslate(boundsToGL, 0, yGap / 2);
    }

    // Render shadow, if any
    GLKVector4 shadowRgba = AP_ColorToVector(_shadowColor);
    shadowRgba.a *= alpha;
    if (shadowRgba.a > 0) {
        for (AP_Font_Run* run in _formattedRuns) {
            AP_CHECK(run, continue);
            CGAffineTransform boundsToShadow = CGAffineTransformTranslate(boundsToGL, _shadowOffset.width, _shadowOffset.height);
            [run renderWithBoundsToGL:boundsToShadow color:shadowRgba];
        }
    }

    // Render text
    for (AP_Font_Run* run in _formattedRuns) {
        if (_hitTestInside && run == _hitTestRun) {
            GLKVector4 rgba = { 0.75, 0.75, 1, alpha };
            [run renderWithBoundsToGL:boundsToGL color:rgba];
        } else {
            [run renderWithBoundsToGL:boundsToGL alpha:alpha];
        }
    }
}

@end
