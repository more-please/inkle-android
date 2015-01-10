#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GAIDictionaryBuilder : NSObject

+ (GAIDictionaryBuilder*) createEventWithCategory:(NSString*) category
                                           action:(NSString*) action
                                            label:(NSString*) label
                                            value:(NSNumber*) value;

// On iOS this is an NSMutableDictionary, but on Android we return
// an opaque reference to a Java Map.
- (jobject) build;

@end
