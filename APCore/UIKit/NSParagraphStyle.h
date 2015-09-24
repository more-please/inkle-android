#pragma once

#import <Foundation/Foundation.h>

#import "UIDefines.h"

// Iain additions
extern NSString* const AP_UrlAttributeName;
extern NSString* const AP_ImageAttributeName;
extern NSString* const AP_TextTransformAttributeName;

typedef NSString* (^AP_TextTransform)(NSString*);

#ifndef APPLE_RUNTIME

// TODO - move to the correct place!

extern NSString* const NSParagraphStyleAttributeName;
extern NSString* const NSFontAttributeName;
extern NSString* const NSKernAttributeName;
extern NSString* const NSForegroundColorAttributeName;

@interface NSParagraphStyle : NSObject <NSCopying, NSMutableCopying>

// These should really be readonly, but overriding them in
// the mutable subclass is a pain. Let's just cheat.
@property(nonatomic) CGFloat lineSpacing;
@property(nonatomic) NSTextAlignment alignment;
@property(nonatomic) CGFloat firstLineHeadIndent;
@property(nonatomic) CGFloat headIndent;
@property(nonatomic) CGFloat tailIndent;
@property(nonatomic) CGFloat paragraphSpacing;
@property(nonatomic) CGFloat paragraphSpacingBefore;
@property(nonatomic) NSLineBreakMode lineBreakMode;

+ (NSParagraphStyle*) defaultParagraphStyle;

@end

@interface NSMutableParagraphStyle : NSParagraphStyle

@end

#endif
