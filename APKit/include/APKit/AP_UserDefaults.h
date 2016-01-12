#pragma once

#import <Foundation/Foundation.h>

@interface AP_UserDefaults : NSObject

+ (void) setDocumentsDir:(NSString*)dir;
+ (AP_UserDefaults*) standardUserDefaults;

- (id) objectForKey:(NSString*)defaultName;
- (void) setObject:(id)value forKey:(NSString*)defaultName;

- (BOOL) boolForKey:(NSString*)defaultName;
- (void) setBool:(BOOL)value forKey:(NSString*)defaultName;

- (NSInteger) integerForKey:(NSString *)defaultName;
- (void) setInteger:(NSInteger)value forKey:(NSString*)defaultName;

- (NSString*) stringForKey:(NSString*)defaultName;
- (NSArray*) stringArrayForKey:(NSString*)defaultName;

- (void) removeObjectForKey:(NSString*)key;

- (BOOL) synchronize;

- (NSDictionary*) dictionaryRepresentation;

@end
