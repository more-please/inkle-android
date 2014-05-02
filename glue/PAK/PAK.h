#pragma once

#import <Foundation/Foundation.h>

// A single resource.
@interface PAK_Item : NSObject
@property(nonatomic,readonly,strong) NSString* path; // Name of the containing file.
@property(nonatomic,readonly) BOOL isAsset; // If YES, the 'file' is an APK asset.
@property(nonatomic,readonly) int offset; // Offset of this resource within the file.
@property(nonatomic,readonly) int length; // Length of this resource.
@property(nonatomic,readonly,strong) NSData* data; // Contents of this resource.

- (instancetype) initWithPath:(NSString*)path isAsset:(BOOL)isAsset offset:(int)offset length:(int)length data:(NSData*)data;
@end

// Interface for a bundle containing multiple named assets.
@protocol PAK_Reader
- (NSArray*) pakNames;
- (PAK_Item*) pakItem:(NSString*)name;
@end

// Implementation of the above: resource bundle stored in a single file or Android asset.
@interface PAK : NSObject <PAK_Reader>

+ (PAK*) pakWithAsset:(NSString*)name data:(NSData*)data;
+ (PAK*) pakWithMemoryMappedFile:(NSString*)filename;

@property(nonatomic,readonly,strong) NSString* path;
@property(nonatomic,readonly) BOOL isAsset;
@property(nonatomic,readonly,strong) NSData* data;

@end

// Singleton holding a list of bundles, which are searched in order for resources.
@interface PAK_Search : NSObject
+ (void) add:(id<PAK_Reader>)pak; // Add the given bundle end of the search path.
+ (NSArray*) names;
+ (PAK_Item*) item:(NSString*)name;
@end
