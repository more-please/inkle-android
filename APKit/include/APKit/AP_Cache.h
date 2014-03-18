#pragma once

#import <Foundation/Foundation.h>

@interface AP_Cache : NSObject

- (id) get:(id)key withLoader:(id(^)(void))block;

@end
