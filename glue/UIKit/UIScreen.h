#pragma once

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface UIScreen : NSObject

+ (UIScreen*) mainScreen;

@property(nonatomic,readonly) CGRect bounds;
@property(nonatomic,readonly) CGRect applicationFrame;
@property(nonatomic,readonly) CGFloat scale;
@property(nonatomic,readonly) CGFloat statusBarHeight;

- (void) setBounds:(CGRect)bounds applicationFrame:(CGRect)frame scale:(CGFloat)scale;

@end
