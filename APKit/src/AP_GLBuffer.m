#import "AP_GLBuffer.h"

#import "AP_Check.h"

@implementation AP_GLBuffer {
    GLuint _name;
    GLenum _target;
    GLenum _usage;
    int _memoryUsage;
}

static int s_totalMemoryUsage = 0;

+ (int) totalMemoryUsage
{
    return s_totalMemoryUsage;
}

- (AP_GLBuffer*) init
{
#ifndef ANDROID
    AP_CHECK([EAGLContext currentContext], return nil);
#endif
    self = [super init];
    if (self) {
        glGenBuffers(1, &_name);
        AP_CHECK(_name, return nil);
        _target = GL_ARRAY_BUFFER;
        _usage = GL_STATIC_DRAW;
    }
    return self;
}

- (void) dealloc
{
    s_totalMemoryUsage -= _memoryUsage;
    glDeleteBuffers(1, &_name);
}

- (GLuint) name
{
    return _name;
}

- (void) bind
{
    glBindBuffer(_target, _name);
}

- (void) bufferTarget:(GLenum)target usage:(GLenum)usage data:(NSData *)data
{
    [self bufferTarget:target usage:usage data:[data bytes] size:[data length]];
}

- (void) bufferTarget:(GLenum)target usage:(GLenum)usage data:(const void *)data size:(size_t)size
{
    _target = target;
    _usage = usage;
    glBindBuffer(_target, _name);
    glBufferData(_target, size, data, _usage);
    AP_CHECK_GL("glBufferData failed", return);

    s_totalMemoryUsage -= _memoryUsage;
    _memoryUsage = size;
    s_totalMemoryUsage += _memoryUsage;
}

+ (AP_GLBuffer*) bufferWithTarget:(GLenum)target usage:(GLenum)usage data:(NSData *)data
{
    AP_GLBuffer* buffer = [[AP_GLBuffer alloc] init];
    if (buffer) {
        [buffer bufferTarget:target usage:usage data:data];
    }
    return buffer;
}

+ (AP_GLBuffer*) bufferWithTarget:(GLenum)target usage:(GLenum)usage data:(const void*)data size:(size_t)size
{
    AP_GLBuffer* buffer = [[AP_GLBuffer alloc] init];
    if (buffer) {
        [buffer bufferTarget:target usage:usage data:data size:size];
    }
    return buffer;
}

@end
