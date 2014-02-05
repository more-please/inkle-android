#pragma once

#import <Foundation/Foundation.h>

@interface AP_Profiler : NSObject

- (void) step:(NSString*)step;
- (void) end;
- (void) maybeReport;

@property(nonatomic) double reportInterval;

@end
