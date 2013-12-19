#pragma once

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface UIScreen : NSObject

+ (UIScreen*) mainScreen;

@property(nonatomic,readonly) CGRect bounds;

@end