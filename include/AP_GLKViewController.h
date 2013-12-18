#pragma once

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#import "AP_GLKView.h"
#import "AP_ViewController.h"

#ifdef AP_REPLACE_UI

@interface AP_GLKViewController : AP_ViewController <AP_GLKViewDelegate>

@end

#else
typedef GLKViewController AP_GLKViewController;
#endif
