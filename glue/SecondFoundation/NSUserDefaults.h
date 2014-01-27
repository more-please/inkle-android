#pragma once

#import <Foundation/Foundation.h>

@interface NSUserDefaults : NSObject

+ (NSUserDefaults*) standardUserDefaults;

- (id) objectForKey:(NSString*)defaultName;
- (void) setObject:(id)value forKey:(NSString*)defaultName;

- (BOOL) boolForKey:(NSString*)defaultName;
- (void) setBool:(BOOL)value forKey:(NSString*)defaultName;

- (NSInteger) integerForKey:(NSString *)defaultName;
- (NSString*) stringForKey:(NSString*)defaultName;
- (NSArray*) stringArrayForKey:(NSString*)defaultName;

- (BOOL) synchronize;

- (NSDictionary*) dictionaryRepresentation;

@end
