#import "AP_GLProgram.h"

#import "AP_Check.h"

static GLuint compileShader(const GLchar* ptr, GLenum type)
{
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &ptr, NULL);
    glCompileShader(shader);
    
#ifndef NDEBUG
    GLint logLength;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif

    GLint status;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    assert(status != 0);
    if (status == 0) {
        glDeleteShader(shader);
        return 0;
    }

    return shader;
}

static BOOL linkProgram(GLuint prog)
{
    GLint status;
    glLinkProgram(prog);

#ifndef NDEBUG
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@implementation AP_GLProgram {
    GLuint _name;
    NSMutableDictionary* _attrs;
    NSMutableDictionary* _uniforms;
}

AP_BAN_EVIL_INIT

- (AP_GLProgram*) initWithVertex:(const char *)vertex fragment:(const char *)fragment
{
#ifndef ANDROID
    AP_CHECK([EAGLContext currentContext], return nil);
#endif
    self = [super init];
    if (self) {
        _name = glCreateProgram();
        _attrs = [NSMutableDictionary dictionary];
        _uniforms = [NSMutableDictionary dictionary];

        GLuint vertexShader = compileShader(vertex, GL_VERTEX_SHADER);
        GLuint fragmentShader = compileShader(fragment, GL_FRAGMENT_SHADER);
        glAttachShader(_name, vertexShader);
        glAttachShader(_name, fragmentShader);
        if (![self link]) {
            AP_LogError("Failed to link GL program");
            return nil;
        }
        AP_CHECK_GL("Failed to create GL program", return nil);
    }
    return self;
}

- (void) dealloc
{
    glDeleteProgram(_name);
}

- (GLuint) name
{
    return _name;
}

- (void) use
{
    glUseProgram(_name);
}

- (GLint) attr:(NSString *)name
{
    AP_CHECK([_attrs valueForKey:name], return 0);
    return [_attrs[name] intValue];
}

- (GLint) uniform:(NSString *)name
{
    AP_CHECK([_uniforms valueForKey:name], return 0);
    return [_uniforms[name] intValue];
}

- (BOOL) link
{
    _attrs = [NSMutableDictionary dictionary];
    _uniforms = [NSMutableDictionary dictionary];
    if (!linkProgram(_name)) {
        return NO;
    }
    GLint count;
    glGetProgramiv(_name, GL_ACTIVE_ATTRIBUTES, &count);
    for (int i = 0; i < count; ++i) {
        char buffer[64];
        GLsizei length;
        GLint size;
        GLenum type;
        glGetActiveAttrib(_name, i, sizeof(buffer), &length, &size, &type, buffer);
        GLint location = glGetAttribLocation(_name, buffer);
        NSString* attr = [[NSString alloc] initWithBytes:buffer length:length encoding:NSASCIIStringEncoding];
        _attrs[attr] = [NSNumber numberWithInt:location];
    }
    glGetProgramiv(_name, GL_ACTIVE_UNIFORMS, &count);
    for (int i = 0; i < count; ++i) {
        char buffer[64];
        GLsizei length;
        GLint size;
        GLenum type;
        glGetActiveUniform(_name, i, sizeof(buffer), &length, &size, &type, buffer);
        GLint location = glGetUniformLocation(_name, buffer);
        NSString* uniform = [[NSString alloc] initWithBytes:buffer length:length encoding:NSASCIIStringEncoding];
        _uniforms[uniform] = [NSNumber numberWithInt:location];
    }
    AP_CHECK_GL("Error linking GL program", return NO);
    return YES;
}

@end
