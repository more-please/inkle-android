#import "AP_GLKTextureLoader.h"

#import "AP_Check.h"
#import "AP_GLTexture.h"

@implementation AP_GLKTextureLoader

+ (AP_GLKTextureInfo*) textureWithContentsOfData:(NSData*)data options:(NSDictionary*)options error:(NSError**)outError
{
    AP_GLKTextureInfo* info = [[AP_GLKTextureInfo alloc] init];
    info.tex = [AP_GLTexture textureWithData:data maxSize:2.15];
    return info;
}

@end
