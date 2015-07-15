#import "AP_GLProgram.h"

#import "AP_Check.h"

#define AP_VERTEX_PREFIX \
    "precision highp float;\n"

#define AP_FRAGMENT_PREFIX \
    "#ifdef GL_FRAGMENT_PRECISION_HIGH\n" \
    "precision highp float;\n" \
    "#else\n" \
    "precision mediump float;\n" \
    "#endif\n"

#define AP_MASK_PREFIX \
    "#define OUTPUT(x) if ((x).a > 0.0) gl_FragColor = (x); else discard\n"

#define AP_NORMAL_PREFIX \
    "#define OUTPUT(x) gl_FragColor = (x)\n"

#define AP_SHARPEN_PREFIX "#define TEXTURE_2D_BIAS(t,p,b) texture2D(t,p,b)\n"
#define AP_VIVANTE_PREFIX "#define TEXTURE_2D_BIAS(t,p,b) texture2D(t,p)\n"

static GLuint compileShader(BOOL mask, const GLchar* ptr, GLenum type)
{
    // Vivante GPU in the HP Slate seems to have a stupid bug. Check for that.
    NSString* vendor = [NSString stringWithUTF8String:(const char*)glGetString(GL_VENDOR)];

    GLuint shader = glCreateShader(type);
    const GLchar* src[4] = {
        (type == GL_VERTEX_SHADER) ? AP_VERTEX_PREFIX : AP_FRAGMENT_PREFIX,
        mask ? AP_MASK_PREFIX : AP_NORMAL_PREFIX,
        [vendor hasPrefix:@"Vivante"] ? AP_VIVANTE_PREFIX : AP_SHARPEN_PREFIX,
        ptr,
    };
    _GL(ShaderSource, shader, 4, src, NULL);
    _GL(CompileShader, shader);

    GLint logLength;
    _GL(GetShaderiv, shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        _GL(GetShaderInfoLog, shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }

    GLint status;
    _GL(GetShaderiv, shader, GL_COMPILE_STATUS, &status);
    assert(status != 0);
    if (status == 0) {
        _GL(DeleteShader, shader);
        return 0;
    }

    return shader;
}

static BOOL linkProgram(GLuint prog)
{
    GLint status;
    _GL(LinkProgram, prog);

    GLint logLength;
    _GL(GetProgramiv, prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        _GL(GetProgramInfoLog, prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }

    _GL(GetProgramiv, prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@implementation AP_GLProgram {
    GLuint _name;
    NSMutableDictionary* _attrs;
    NSMutableDictionary* _uniforms;
    AP_GLProgram* _maskProg;
}

AP_BAN_EVIL_INIT

- (AP_GLProgram*) initWithVertex:(const char *)vertex fragment:(const char *)fragment
{
    return [self initWithVertex:vertex fragment:fragment mask:NO];
}

- (AP_GLProgram*) initWithVertex:(const char *)vertex fragment:(const char *)fragment mask:(BOOL)mask
{
    self = [super init];
    if (self) {
        _name = glCreateProgram();
        _attrs = [NSMutableDictionary dictionary];
        _uniforms = [NSMutableDictionary dictionary];
        if (!mask) {
            // I am not a mask, therefore I need to create one
            _maskProg = [[AP_GLProgram alloc] initWithVertex:vertex fragment:fragment mask:YES];
        }

        GLuint vertexShader = compileShader(mask, vertex, GL_VERTEX_SHADER);
        GLuint fragmentShader = compileShader(mask, fragment, GL_FRAGMENT_SHADER);
        _GL(AttachShader, _name, vertexShader);
        _GL(AttachShader, _name, fragmentShader);
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
    _GL(DeleteProgram, _name);
}

- (GLuint) name
{
    return _name;
}

static BOOL _g_useMask = NO;

+ (BOOL) useMask:(BOOL)newValue;
{
    BOOL oldValue = _g_useMask;
    _g_useMask = newValue;
    return oldValue;
}

- (void) use
{
    if (_g_useMask && _maskProg) {
        _GL(UseProgram, _maskProg->_name);
    } else {
        _GL(UseProgram, _name);
    }
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
    _GL(GetProgramiv, _name, GL_ACTIVE_ATTRIBUTES, &count);
    for (int i = 0; i < count; ++i) {
        char buffer[64];
        GLsizei length;
        GLint size;
        GLenum type;
        _GL(GetActiveAttrib, _name, i, sizeof(buffer), &length, &size, &type, buffer);
        GLint location = glGetAttribLocation(_name, buffer);
        NSString* attr = [[NSString alloc] initWithBytes:buffer length:length encoding:NSASCIIStringEncoding];
        _attrs[attr] = [NSNumber numberWithInt:location];
    }
    _GL(GetProgramiv, _name, GL_ACTIVE_UNIFORMS, &count);
    for (int i = 0; i < count; ++i) {
        char buffer[64];
        GLsizei length;
        GLint size;
        GLenum type;
        _GL(GetActiveUniform, _name, i, sizeof(buffer), &length, &size, &type, buffer);
        GLint location = glGetUniformLocation(_name, buffer);
        NSString* uniform = [[NSString alloc] initWithBytes:buffer length:length encoding:NSASCIIStringEncoding];
        _uniforms[uniform] = [NSNumber numberWithInt:location];
    }
    AP_CHECK_GL("Error linking GL program", return NO);
    return YES;
}

@end
