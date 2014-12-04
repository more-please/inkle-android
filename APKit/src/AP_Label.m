#import "AP_Label.h"

#import <UIKit/UIKit.h>

#import "AP_Application.h"
#import "AP_Check.h"
#import "AP_Control.h"
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
    NSParagraphStyle* _currentStyle;
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

    _text = [[NSMutableAttributedString alloc] initWithString:@""];
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
    // If we auto-scaled to fit the given size, return our preferred size.
    // Also add a little buffer to ensure we don't set the label to exactly
    // this size, then find due to numerical error that it no longer fits.
    CGSize result = {
        _formattedSize.width / _fontScale + 0.1,
        _formattedSize.height / _fontScale + 0.1
    };
    return result;
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
    _text = [[NSMutableAttributedString alloc] initWithString:text];

    NSRange r = NSMakeRange(0, _text.length);
    [_text addAttribute:NSFontAttributeName value:_font range:r];
    [_text addAttribute:NSForegroundColorAttributeName value:_textColor range:r];

    NSMutableParagraphStyle* style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = _lineSpacing;
    style.alignment = _alignment;
    [_text addAttribute:NSParagraphStyleAttributeName value:style range:r];

    [self setNeedsTextLayout];
}

- (AP_Font*) font
{
    if (_text.length > 0) {
        return [_text attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
    } else {
        return _font;
    }
}

- (void) setFont:(AP_Font*)font
{
    if (font != _font) {
        _font = font;

        NSRange r = NSMakeRange(0, _text.length);
        [_text addAttribute:NSFontAttributeName value:_font range:r];

        [self setNeedsTextLayout];
    }
}

- (UIColor*) textColor
{
    if (_text.length > 0) {
        return [_text attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:NULL];
    } else {
        return _textColor;
    }
}

- (void) setTextColor:(UIColor*)color
{
    if (!GLKVector4AllEqualToVector4(color.rgba, _textColor.rgba)) {
        _textColor = color;

        NSRange r = NSMakeRange(0, _text.length);
        [_text addAttribute:NSForegroundColorAttributeName value:_textColor range:r];

        [self setNeedsTextLayout];
    }
}

- (void) setTextAlignment:(NSTextAlignment)alignment
{
    if (alignment != _alignment) {
        _alignment = alignment;

        NSRange r = NSMakeRange(0, _text.length);
        NSMutableParagraphStyle* style = [[NSMutableParagraphStyle alloc] init];
        style.lineSpacing = _lineSpacing;
        style.alignment = _alignment;
        [_text addAttribute:NSParagraphStyleAttributeName value:style range:r];

        [self setNeedsTextLayout];
    }
}

- (void) setLineSpacingAdjustment:(CGFloat)adjustment
{
    if (adjustment != _lineSpacing) {
        _lineSpacing = adjustment;

        NSRange r = NSMakeRange(0, _text.length);
        NSMutableParagraphStyle* style = [[NSMutableParagraphStyle alloc] init];
        style.lineSpacing = _lineSpacing;
        style.alignment = _alignment;
        [_text addAttribute:NSParagraphStyleAttributeName value:style range:r];

        [self setNeedsTextLayout];
    }
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
            case NSTextAlignmentRight:
                offset.x = xGap;
                break;

            case NSTextAlignmentCenter:
                offset.x = xGap / 2;
                break;

            case NSTextAlignmentJustified:
                AP_NOT_IMPLEMENTED;
                // fall through
            case NSTextAlignmentLeft:
            case NSTextAlignmentNatural:
            default:
                offset.x = 0;
                break;
        }

        // Calculate y adjustment based on maximum ascent and line height.
        CGFloat maxAscent = 0;
        CGFloat maxLineHeight = 0;
        CGFloat lineSpacing = _currentStyle.lineSpacing;
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

    if (_adjustsFontSizeToFitWidth && width > 0 && _formattedSize.width > width) {
        _fontScale = MAX(0.1, width / _formattedSize.width);
        [self scaledTextLayoutWithWidth:width];
    }
}

- (void) scaledTextLayoutWithWidth:(CGFloat)width
{
    NSString* str = [_text string];
//    NSLog(@"%@ layout w=%f {%@}", self, width, str);

    NSParagraphStyle* defaultStyle = [NSParagraphStyle defaultParagraphStyle];
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
        AP_Font* font = [attrs objectForKey:NSFontAttributeName];
        if (!font) {
            font = defaultFont;
        }
        font = [font fontWithSize:(font.pointSize * _fontScale)];

        NSNumber* kerning = [attrs objectForKey:NSKernAttributeName];

        UIColor* color = [attrs objectForKey:NSForegroundColorAttributeName];
        if (!color) {
            color = defaultColor;
        }
        _currentStyle = [attrs objectForKey:NSParagraphStyleAttributeName];
        if (!_currentStyle) {
            _currentStyle = defaultStyle;
        }
        NSString* url = [attrs objectForKey:AP_UrlAttributeName];

        // Parse the characters.
        NSString* chars = [str substringWithRange:range];

        AP_TextTransform t = [attrs objectForKey:AP_TextTransformAttributeName];
        if (t) {
            chars = t(chars);
        }

        AP_Font_Run* run = [font runForString:chars kerning:kerning.floatValue];
        run.textColor = color;
        run.image = [attrs objectForKey:AP_ImageAttributeName];

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

    // Attempt to replicate the behaviour of UIControl.contentVerticalAlignment.
    // Apparently this "specifies the alignment of text or image within the receiver"
    // but the docs don't explain about how it does this, except to say that the
    // default is 'top'. It's actually 'centre', so fucking thanks for that, Apple.
    // Let's just assume that any label whose immediate parent is a UIControl should
    // be centered vertically. This is nasty but should work for our purposes.
    BOOL stupidVerticalAlignmentHack = [self.superview isKindOfClass:[AP_Control class]];

    if (_centerVertically || _numberOfLines == 1 || stupidVerticalAlignmentHack) {
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
