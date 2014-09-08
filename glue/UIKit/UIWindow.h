#pragma once

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#import "UIViewController.h"

@interface UIWindow : NSObject

@property(nonatomic,strong) Real_UIViewController* rootViewController;

- (id) initWithFrame:(CGRect)frame;

- (void) makeKeyAndVisible;

@end
