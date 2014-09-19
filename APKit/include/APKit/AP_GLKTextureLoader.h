#pragma once

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#import "AP_GLKTextureInfo.h"

@interface AP_GLKTextureLoader : NSObject

+ (AP_GLKTextureInfo*) textureWithContentsOfData:(NSData*)data options:(NSDictionary*)options error:(NSError**)outError;

@end
