#pragma once

#import <Foundation/Foundation.h>

// A single resource.
@interface PAK_Item : NSObject
@property(nonatomic,readonly,strong) NSString* name; // Name of the resource.
@property(nonatomic,readonly) BOOL isCompressed;
@property(nonatomic,readonly) int length; // Uncompressed length of this resource.
@property(nonatomic,readonly,strong) NSData* data; // Uncompressed contents of this resource.
@end

// Interface for a bundle containing multiple named assets.
@protocol PAK_Reader
- (NSArray*) pakNames;
- (PAK_Item*) pakItem:(NSString*)name;
@end

// Implementation of the above: resource bundle stored in a single file or Android asset.
@interface PAK : NSObject <PAK_Reader>

+ (PAK*) pakWithData:(NSData*)data;
+ (PAK*) pakWithMemoryMappedFile:(NSString*)filename;

@property(nonatomic,readonly,strong) NSData* data;

@end

// Notification sent when the search path changes. Time to flush caches!
extern NSString* const PAK_SearchPathChangedNotification;

// Singleton holding a list of bundles, which are searched in order for resources.
@interface PAK_Search : NSObject
+ (void) add:(id<PAK_Reader>)pak; // Add the given bundle end of the search path.
+ (void) remove:(id<PAK_Reader>)pak; // Remove the given bundle.
+ (NSArray*) names;
+ (PAK_Item*) item:(NSString*)name;
@end
