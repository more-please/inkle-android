#pragma once

#import "GAITracker.h"

@interface GAI : NSObject

+ (GAI*) sharedInstance;

@property(nonatomic,assign) id<GAITracker> defaultTracker;

@end
