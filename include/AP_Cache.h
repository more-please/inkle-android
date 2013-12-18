#pragma once

#import <Foundation/Foundation.h>

@interface AP_Cache : NSObject

- (id) get:(NSString*)name withLoader:(id(^)(void))block;

@end
