#import <GLKit/GLKit.h>

#ifdef AP_REPLACE_UI

@interface AP_GLKEffectPropertyTexture : NSObject

@property (nonatomic, assign) GLuint name;

@end

#else
typedef GLKEffectPropertyTexture AP_GLKEffectPropertyTexture;
#endif
