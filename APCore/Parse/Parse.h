#pragma once

#import <Foundation/Foundation.h>

@interface Parse : NSObject

- (instancetype) initWithApplicationId:(NSString*)applicationId clientKey:(NSString*)clientKey;

- (void) call:(NSString*)function args:(NSDictionary*)args block:(void(^)(NSError*, NSString*)) block;
- (void) save:(NSString*)className data:(NSDictionary*)data block:(void(^)(NSError*))block;
- (void) query:(NSString*)className where:(NSDictionary*)data block:(void(^)(NSError*, NSArray*))block;

@end
