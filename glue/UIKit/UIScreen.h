#pragma once

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface UIScreen : NSObject

+ (UIScreen*) mainScreen;

@property(nonatomic,readonly) CGRect bounds;
@property(nonatomic,readonly) CGFloat scale;

- (void) setSize:(CGSize)size scale:(CGFloat)scale;

@end
