#import "AP_WebView.h"

#import <stdarg.h>

#import <libxml/HTMLparser.h>
#import <libxml/tree.h>

#import "INKAttributedStringParagraphStyle.h"

#import "AP_Bundle.h"
#import "AP_Check.h"
#import "AP_Image.h"
#import "AP_Label.h"
#import "AP_Window.h"

@implementation AP_WebView {
    AP_Label* _label;
}

AP_BAN_EVIL_INIT;

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        LIBXML_TEST_VERSION;

        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        _scrollView = [[AP_ScrollView alloc] initWithFrame:self.bounds];
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        [self addSubview:_scrollView];

        _label = [[AP_Label alloc] initWithFrame:self.bounds];
        _label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        [_scrollView addSubview:_label];
    }
    return self;
}

- (void) dealloc
{
    xmlCleanupParser();
}

static BOOL isTags(xmlNode* n, const char* tags, ...) {
    if (n->type != XML_ELEMENT_NODE) {
        return NO;
    }

    const char* c = (const char*) n->name;
    BOOL found = (strcmp(c, tags) == 0);

    va_list args;
    va_start(args, tags);
    const char* tag = va_arg(args, const char*);
    while (tag) {
        if (strcmp(c, tag) == 0) {
            found = YES;
        }
        tag = va_arg(args, const char*);
    }
    va_end(args);

    return found;
}

static BOOL isTag(xmlNode* n, const char* tag) {
    if (n->type != XML_ELEMENT_NODE) {
        return NO;
    }
    if (strcmp((const char*) n->name, tag) == 0) {
        return YES;
    }
    return NO;
}

- (NSAttributedString*) parseText:(xmlNode*)n attrs:(NSDictionary*)attrs
{
    if (n->type == XML_TEXT_NODE) {
        NSString* content = [NSString stringWithUTF8String:(const char*)n->content];
        return [[NSMutableAttributedString alloc]
            initWithString:content
            attributes:attrs];
    }

    if (isTag(n, "strong")) {
        UIFont* font = [attrs objectForKey:kINKAttributedStringFontAttribute];
        font = [UIFont fontWithName:@"Baskerville-Bold" size:font.pointSize];
        attrs = [attrs mutableCopy];
        [attrs setValue:font forKey:kINKAttributedStringFontAttribute];
    }

    if (isTag(n, "em")) {
        UIFont* font = [attrs objectForKey:kINKAttributedStringFontAttribute];
        font = [UIFont fontWithName:@"Baskerville-Italic" size:font.pointSize];
        attrs = [attrs mutableCopy];
        [attrs setValue:font forKey:kINKAttributedStringFontAttribute];
    }

    if (isTag(n, "a")) {
        // Hyperlinks in Holo blue: http://developer.android.com/design/style/color.html
        UIColor* color = [UIColor colorWithRed:0.2 green:0.71 blue:0.9 alpha:1];
        attrs = [attrs mutableCopy];
        [attrs setValue:color forKey:kINKAttributedStringColorAttribute];
    }

    // Hack -- just so happens there's only one <span> in credits.css
    if (isTag(n, "span")) {
        UIFont* font = [attrs objectForKey:kINKAttributedStringFontAttribute];
        font = [UIFont fontWithName:@"Baskerville-Bold" size:font.pointSize * 1.2];
        attrs = [attrs mutableCopy];
        [attrs setValue:font forKey:kINKAttributedStringFontAttribute];
    }

    NSMutableAttributedString* buffer = [NSMutableAttributedString new];
    for (n = n->children; n; n = n->next) {
        NSAttributedString* s = [self parseText:n attrs:attrs];
        [buffer appendAttributedString:s];
    }
    return buffer;
}


- (NSAttributedString*) parseBody:(xmlNode*)n attrs:(NSDictionary*)attrs
{
    NSMutableAttributedString* buffer = [NSMutableAttributedString new];

    NSString* font = @"Baskerville";
    CGFloat size = 16;

    if (isTags(n, "p", "h1", "h2", "h3", NULL)) {

        CGFloat margin = [AP_Window iPhone:32 iPad:150 iPadLandscape:200];

        INKAttributedStringParagraphStyle* style = [INKAttributedStringParagraphStyle style];
        style.alignment = kCTTextAlignmentCenter;
        style.firstLineHeadIndent = margin;
        style.headIndent = margin;
        style.tailIndent = -margin;
        style.paragraphSpacing = 5;

        if (isTags(n, "h1", "h2", NULL)) {
            font = @"Baskerville-Bold";
            style.paragraphSpacingBefore = [AP_Window scaleForIPhone:45 iPad:90];
            style.paragraphSpacing = [AP_Window scaleForIPhone:30 iPad:60];
            size = [AP_Window scaleForIPhone:24 iPad:32];
        } else if (isTag(n, "h3")) {
            // TODO: fancy letter-spacing
            style.paragraphSpacingBefore = [AP_Window scaleForIPhone:30 iPad:45];
            size = 19;
        } else {
            style.paragraphSpacingBefore = 10;
            size = 16;
        }
        
        attrs = @{
            kINKAttributedStringColorAttribute:[attrs objectForKey:kINKAttributedStringColorAttribute],
            kINKAttributedStringFontAttribute:[UIFont fontWithName:font size:size],
            kINKAttributedStringParagraphStyleAttribute:style
        };

        for (n = n->children; n; n = n->next) {
            NSAttributedString* s = [self parseText:n attrs:attrs];
            [buffer appendAttributedString:s];
        }

        NSAttributedString* end = [[NSAttributedString alloc] initWithString:@"\n" attributes:attrs];
        [buffer appendAttributedString:end];

    } else if (isTag(n, "img")) {
        NSString* src = nil;
        int width = 0;
        for (xmlAttr* a = n->properties; a; a = a->next) {
            if (strcmp((const char*) a->name, "src") == 0) {
                src = [NSString stringWithUTF8String:(const char*)a->children->content];
            }
            if (strcmp((const char*) a->name, "width") == 0) {
                width = atoi((const char*)a->children->content);
            }
        }

        AP_Image* image = nil;
        if (src) {
            image = [AP_Image imageWithContentsOfFileNamedAuto:src];
        }
        if (image) {
            if (width) {
                image = [image imageWithWidth:width];
            }

            UIFont* f = [UIFont fontWithName:font size:size];
            INKAttributedStringParagraphStyle* style = [INKAttributedStringParagraphStyle style];
            style.alignment = kCTTextAlignmentCenter;
            style.paragraphSpacing = 20;
            style.paragraphSpacingBefore = 20;

            [buffer appendAttributedString:[[NSAttributedString alloc]
                initWithString:@"*"
                attributes:@{
                    kINKAttributedStringFontAttribute:f,
                    kINKAttributedStringParagraphStyleAttribute:style,
                    kINKAttributedStringImageAttribute:image,
                }
            ]];

            [buffer appendAttributedString:[[NSAttributedString alloc]
                initWithString:@"\n"
                attributes:@{
                    kINKAttributedStringFontAttribute:f,
                    kINKAttributedStringParagraphStyleAttribute:style,
                }
            ]];
        }
    } else {
        for (n = n->children; n; n = n->next) {
            NSAttributedString* s = [self parseBody:n attrs:attrs];
            [buffer appendAttributedString:s];
        }
    }
    return buffer;
}

- (NSAttributedString*) parseHtml:(xmlNode*)n attrs:(NSDictionary*)attrs
{
    NSMutableAttributedString* buffer = [NSMutableAttributedString new];
    for (n = n->children; n; n = n->next) {
        NSAttributedString* s;
        if (isTag(n, "body")) {
            s = [self parseBody:n attrs:attrs];
        } else {
            s = [self parseHtml:n attrs:attrs];
        }
        [buffer appendAttributedString:s];
    }
    return buffer;
}

- (void) loadHtmlResource:(NSString*)name
{
    if ([_delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [_delegate webViewDidStartLoad:self];
    }
    
    NSData* data = [AP_Bundle dataForResource:name ofType:nil];
    xmlDoc* doc = htmlReadMemory((const char*)data.bytes, data.length, name.cString, NULL, 0);
    xmlNode* root = xmlDocGetRootElement(doc);

    NSAttributedString* text = [self parseHtml:root attrs:@{
        kINKAttributedStringColorAttribute:[UIColor whiteColor],
    }];

    xmlFreeDoc(doc);

    _label.attributedText = text;
    _label.centerVertically = NO;
    _label.numberOfLines = 0;

    if ([_delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [_delegate webViewDidFinishLoad:self];
    }
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    if (_label) {
        CGFloat margin = [AP_Window scaleForIPhone:50 iPad:100];

        CGSize viewSize = _scrollView.frame.size;
        CGSize textSize = [_label sizeThatFits:viewSize];
        textSize.width = viewSize.width;

        _scrollView.contentSize = CGSizeMake(textSize.width, textSize.height + 4 * margin);
        _label.frame = CGRectMake(0, margin, textSize.width, textSize.height);
    }
}

@end
