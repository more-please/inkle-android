#pragma once

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#import "AP_GLKView.h"
#import "AP_ViewController.h"

@interface AP_GLKViewController : AP_ViewController <AP_GLKViewDelegate>

/*
 Used to pause and resume the controller.
 */
@property (nonatomic, getter=isPaused) BOOL paused;

@end
