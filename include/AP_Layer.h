#pragma once

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

#ifdef AP_REPLACE_UI

@interface AP_Layer : NSObject

@property(nonatomic) CGFloat zPosition;

#ifdef ANDROID
@property(nonatomic,strong) UIColor* shadowColor; // Default is black
#else
@property(nonatomic,strong) CGColorRef shadowColor; // Default is black
#endif
@property(nonatomic) float shadowOpacity; // Default is 0
@property(nonatomic) CGSize shadowOffset; // Default is (0, -3)
@property(nonatomic) CGFloat shadowRadius; // Default is 3
@property(nonatomic) CGFloat cornerRadius; // Default is 0

@property(nonatomic,strong) AP_Layer* mask; // Wow, I hope nobody actually uses this
@property(nonatomic) CGPoint anchorPoint; // Default is (0.5, 0.5), i.e. the center of the bounds rect
@property(nonatomic) CGPoint position;

- (void)removeAllAnimations;

@end

#else
typedef CALayer AP_Layer;
#endif