#pragma once

#import <Foundation/Foundation.h>

@interface GAIDictionaryBuilder : NSObject

+ (GAIDictionaryBuilder *)createEventWithCategory:(NSString *)category
                                           action:(NSString *)action
                                            label:(NSString *)label
                                            value:(NSNumber *)value;

- (NSMutableDictionary *)build;

@end
