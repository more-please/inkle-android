#pragma once

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface UIViewController : NSObject

@property (nonatomic, getter=isPaused) BOOL paused;

- (void) draw;

@end
