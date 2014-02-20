#import "AP_WebView.h"

#import <stdarg.h>

#import <libxml/HTMLparser.h>
#import <libxml/tree.h>

#import "INKAttributedStringParagraphStyle.h"

#import "AP_Bundle.h"
#import "AP_Check.h"
#import "AP_Label.h"
#import "AP_Window.h"

@implementation AP_WebView

AP_BAN_EVIL_INIT;

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        LIBXML_TEST_VERSION;

        _scrollView = [[AP_ScrollView alloc] initWithFrame:self.bounds];
        [self addSubview:_scrollView];
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

    if (isTags(n, "p", "h1", "h2", "h3", NULL)) {

        CGFloat margin = [AP_Window iPhone:32 iPad:150 iPadLandscape:200];

        INKAttributedStringParagraphStyle* style = [INKAttributedStringParagraphStyle style];
        style.alignment = kCTTextAlignmentCenter;
        style.firstLineHeadIndent = margin;
        style.headIndent = margin;
        style.tailIndent = -margin;

        NSString* font = @"Baskerville";
        CGFloat size;
        if (isTags(n, "h1", "h2", NULL)) {
            style.paragraphSpacingBefore = [AP_Window scaleForIPhone:30 iPad:60];
            style.paragraphSpacing = [AP_Window scaleForIPhone:30 iPad:60];
            size = [AP_Window scaleForIPhone:24 iPad:32];
        } else if (isTag(n, "h3")) {
            style.paragraphSpacingBefore = [AP_Window scaleForIPhone:20 iPad:30];
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

    AP_Label* label = [[AP_Label alloc] initWithFrame:self.bounds];
    label.attributedText = text;

    CGSize viewSize = _scrollView.frame.size;
    CGSize textSize = [label sizeThatFits:viewSize];
    textSize.width = viewSize.width;
    textSize.height += [AP_Window scaleForIPhone:300 iPad:500];

    [_scrollView addSubview:label];

    _scrollView.contentSize = textSize;
    label.frame = CGRectMake(0, 0, textSize.width, textSize.height);

    if ([_delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [_delegate webViewDidFinishLoad:self];
    }
}

@end
