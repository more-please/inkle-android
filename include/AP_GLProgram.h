#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>

@interface AP_GLProgram : NSObject

@property (readonly) GLuint name;

- (AP_GLProgram*) initWithVertex:(const char*)vertex fragment:(const char*)fragment;

- (GLint) attr:(NSString*)name;
- (GLint) uniform:(NSString*)name;
- (void) use;

@end
