#pragma once

#import <Foundation/Foundation.h>

#ifdef AP_REPLACE_UI

#import "AP_ViewController.h"

@protocol AP_NavigationControllerDelegate <NSObject>
@end

@interface AP_NagivationController : AP_ViewController
@end

#else
typedef UINavigationController AP_NavigationController;
#define AP_NavigationControllerDelegate UINavigationControllerDelegate
#endif
