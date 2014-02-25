#pragma once

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#import "AP_ViewController.h"

@class AP_GLKView;

@protocol AP_GLKViewDelegate <NSObject>
@required
- (void)update;
- (void)glkView:(AP_GLKView *)view drawWithAlpha:(CGFloat)alpha;
@end

@interface AP_GLKView : AP_View

@property id <AP_GLKViewDelegate> delegate;

@end
