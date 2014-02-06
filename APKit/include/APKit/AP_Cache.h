#pragma once

#import <Foundation/Foundation.h>

@interface AP_Cache : NSObject

@property(nonatomic) int size;

- (instancetype) initWithSize:(int)size;

- (id) get:(id)key withLoader:(id(^)(void))block;

@end
