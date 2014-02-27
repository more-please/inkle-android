#pragma once

#import <Foundation/Foundation.h>

@interface NSUserDefaults : NSObject

+ (void) setDocumentsDir:(NSString*)dir;
+ (NSUserDefaults*) standardUserDefaults;

- (id) objectForKey:(NSString*)defaultName;
- (void) setObject:(id)value forKey:(NSString*)defaultName;

- (BOOL) boolForKey:(NSString*)defaultName;
- (void) setBool:(BOOL)value forKey:(NSString*)defaultName;

- (NSInteger) integerForKey:(NSString *)defaultName;
- (NSString*) stringForKey:(NSString*)defaultName;
- (NSArray*) stringArrayForKey:(NSString*)defaultName;

- (void) removeObjectForKey:(NSString*)key;

- (BOOL) synchronize;

- (NSDictionary*) dictionaryRepresentation;

@end
