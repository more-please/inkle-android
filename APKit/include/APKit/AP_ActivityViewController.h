#pragma once

#import <Foundation/Foundation.h>

#import "AP_ViewController.h"

@interface AP_ActivityViewController : AP_ViewController

- (instancetype) initWithActivityItems:(NSArray*)activityItems applicationActivities:(NSArray*)applicationActivities;

@end
