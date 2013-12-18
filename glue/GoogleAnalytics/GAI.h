#pragma once

#import <Foundation/Foundation.h>

#import "GAITracker.h"

@interface GAI : NSObject

+ (GAI*) sharedInstance;

@property(nonatomic,assign) id<GAITracker> defaultTracker;

@end
