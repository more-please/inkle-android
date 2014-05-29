#pragma once

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <GLKit/GLKit.h>

#import "AP_ViewController.h"

extern NSString* const AP_ScreenSizeChangedNotification;

// Plays the role of a UIWindow containing UIViews.
// Actually implemented as a GL-based UIView.

@interface AP_Window : GLKViewController

@property (readonly) CGRect bounds;

@property AP_ViewController* rootViewController;

- (void) resetAllGestures;

+ (CGRect) screenBounds;
+ (CGSize) screenSize;
+ (CGFloat) screenScale;

// Set the scissor rect, returning the previous rect.
+ (CGRect) setScissorRect:(CGRect)glBounds;

// As above, but intersect with the previous rect.
+ (CGRect) overlayScissorRect:(CGRect)glBounds;

// Get a metric scaled to fit the current device, such that it has
// the specified values on a Retina iPhone (3.5") or iPad. We'll
// interpolate between the given values for other screen sizes.
// (For non-Retina devices, the value will be divided by 2.)
+ (CGFloat) widthForIPhone:(CGFloat)iPhone iPad:(CGFloat)iPad;
+ (CGFloat) heightForIPhone:(CGFloat)iPhone iPad:(CGFloat)iPad;
+ (CGFloat) scaleForIPhone:(CGFloat)iPhone iPad:(CGFloat)iPad;

// As above, but scale the value appropriately if we're in landscape mode.
+ (CGFloat) iPhone:(CGFloat)iPhone iPad:(CGFloat)iPad iPadLandscape:(CGFloat)landscape;

- (BOOL) isHitTestView:(AP_View*)view;
- (BOOL) isGestureView:(AP_View*)view;

@end
