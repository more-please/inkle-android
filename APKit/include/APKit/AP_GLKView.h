#pragma once

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#import "AP_Image.h"
#import "AP_ViewController.h"

@class AP_GLKView;

@protocol AP_GLKViewDelegate <NSObject>
@required
- (void)update;
- (void)glkView:(AP_GLKView*)view drawWithAlpha:(CGFloat)alpha;
- (void)glkView:(AP_GLKView*)view drawInRect:(CGRect)rect;
@end

@interface AP_GLKView : AP_View

@property (nonatomic,weak) id <AP_GLKViewDelegate> delegate;

/*
 Returns a UIImage of the resulting draw. Snapshot should never be called from within the draw method or from a
 thread other than the main thread.
 */
- (AP_Image*) snapshot;

@end
