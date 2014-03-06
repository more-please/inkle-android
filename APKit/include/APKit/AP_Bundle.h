#pragma once

#import <Foundation/Foundation.h>

#import "AP_Application.h"
#import "AP_PakReader.h"

// Wrapper for NSBundle. Also allows resource to be loaded from external .pak files.
// We use this on Android to manage extension files.
@interface AP_Bundle : NSObject

// Looks for the given resource in the .pak file(s), if any, then the main bundle.
+ (NSData*) dataForResource:(NSString *)name ofType:(NSString *)ext;

// Add the given .pak file to the end of the resource search path.
+ (void) addPak:(AP_PakReader*)pak;

+ (AP_Bundle*) mainBundle;

@property(nonatomic,strong) NSString* root;

// Like pathsForResources, but returns the bundle-relative resource name.
- (NSArray*) namesForResourcesOfType:(NSString*)ext inDirectory:(NSString*)dir;

//- (NSArray*) pathsForResourcesOfType:(NSString*)ext inDirectory:(NSString*)dir;
//- (NSString*) pathForResource:(NSString*)name ofType:(NSString*)ext;
//- (NSString*) pathForResource:(NSString*)name ofType:(NSString*)ext inDirectory:(NSString*)subpath;
//- (NSURL*) URLForResource:(NSString*)name withExtension:(NSString*)ext;

- (NSDictionary*) infoDictionary;
- (id) objectForInfoDictionaryKey:(NSString*)key;

@end
