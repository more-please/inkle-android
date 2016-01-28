#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GAIDictionaryBuilder : NSObject

+ (GAIDictionaryBuilder*) createEventWithCategory:(NSString*) category
                                           action:(NSString*) action
                                            label:(NSString*) label
                                            value:(NSNumber*) value;

- (NSDictionary*) build;

@end
