#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#ifdef AP_REPLACE_UI

@interface AP_GLKEffectPropertyTransform : NSObject

@property (nonatomic) GLKMatrix4 modelviewMatrix;
@property (nonatomic) GLKMatrix4 projectionMatrix;

@end

#else
typedef GLKEffectPropertyTransform AP_GLKEffectPropertyTransform;
#endif
