#import "AP_BookView.h"

#import <GLKit/GLKit.h>

#import <vector>

#import "AP_Check.h"
#import "AP_GLBuffer.h"
#import "AP_GLProgram.h"
#import "AP_GLTexture.h"
#import "AP_Utils.h"
#import "AP_Touch.h"

#ifdef SORCERY_SDL
#import <SDL2/SDL.h>
#endif

using namespace std;

@implementation AP_BookView {
    __weak id<AP_BookViewDelegate> _delegate;
    int _currentPage;
    int _pageCount;
    vector<float> _pos;
    vector<float> _destPos;
}

- (instancetype) initWithPageCount:(int)pageCount delegate:(id<AP_BookViewDelegate>)delegate frame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _delegate = delegate;
        _pageCount = pageCount;
        _pos.resize(pageCount);
        _destPos.resize(pageCount);

        [self setCurrentPage:0 animated:NO];
    }
    return self;
}

- (int) currentPage
{
    return _currentPage;
}

- (void) setCurrentPage:(int)currentPage animated:(BOOL)animated
{
    // Round down to left-hand page
    _currentPage = 2 * AP_CLAMP(currentPage / 2, 0, (_pos.size() - 1) / 2);

    for (int i = 0; i < _pos.size(); ++i) {
        _destPos[i] = (i <= _currentPage) ? 1 : 0;
    }

    if (!animated) {
        _pos = _destPos;
    }

    [self setNeedsDisplay];
}

- (BOOL) handleKeyDown:(int)key
{
    switch (key) {
        case SDLK_LEFT:
        case SDLK_BACKSPACE:
            [self setCurrentPage:_currentPage - 2 animated:YES];
            return YES;

        case SDLK_RIGHT:
        case SDLK_SPACE:
        case SDLK_RETURN:
            [self setCurrentPage:_currentPage + 2 animated:YES];
            return YES;

        default:
            return NO;
    }
}

- (void) touchesBegan:(NSSet*)touches withEvent:(AP_Event *)event
{
    for (AP_Touch* touch in touches) {
        CGPoint p = [touch locationInView:self];
        if (p.x < self.bounds.size.width / 2) {
            [self setCurrentPage:_currentPage - 2 animated:YES];
        } else {
            [self setCurrentPage:_currentPage + 2 animated:YES];
        }
    }
}

// Needs some work -- ideally it would feel like direct manipulation when
// there's real touch input (e.g. trackpad) but turn a page at a time when
// used with a clicky scroll wheel.
- (BOOL) handleMouseWheelX:(float)x Y:(float)y
{
    float delta = -(x + y); // Polarity seems right for OS X, need to check on more platforms...
    if (delta > 0) {
        [self setCurrentPage:_currentPage + 2 animated:YES];
    } else {
        [self setCurrentPage:_currentPage - 2 animated:YES];
    }
    return YES;
}

- (void) updateGL:(float)dt
{
    const float kSpeed = 2.5;
    const float kMinGap = 0.01;

    const float step = dt * kSpeed;

    vector<float> nextPos = _pos;
    bool needsDisplay = false;

    // Handle pages flipping forward, making sure they don't hit the previous page.
    for (int i = 0; i < _pos.size(); ++i) {
        float delta = _destPos[i] - _pos[i];
        if (delta > 0) {
            nextPos[i] = MIN(_pos[i] + step, _destPos[i]);
            int prevPage = i - 1;
            if (prevPage >= 0 && nextPos[prevPage] < 1) {
                nextPos[i] = MIN(nextPos[i], nextPos[prevPage] - kMinGap);
            }
            needsDisplay = true;
        }
    }

    // Handle pages flipping backward, making sure they don't hit the next page.
    for (int i = _pos.size() - 1; i >= 0; --i) {
        float delta = _destPos[i] - _pos[i];
        if (delta < 0) {
            nextPos[i] = MAX(_pos[i] - step, _destPos[i]);
            int nextPage = i + 1;
            if (nextPage < _pos.size() && nextPos[nextPage] > 0) {
                nextPos[i] = MAX(nextPos[i], nextPos[nextPage] + kMinGap);
            }
            needsDisplay = true;
        }
    }

    if (needsDisplay) {
        _pos.swap(nextPos);
        [self setNeedsDisplay];
    }
}

- (void) renderWithBoundsToGL:(CGAffineTransform)boundsToGL alpha:(CGFloat)alpha
{
    static const char* kVertex = AP_SHADER(
        uniform mat4 transform;
        attribute vec2 pos;
        uniform float pagePos; // 0 = on right, 1 = on left
        uniform float pageFlip; // 0 = normal texture coordinates, 1 = flipped horizontally
        varying vec2 _texCoord;

        float cubic_hermite_spline(float t, float dydt0, float dydt1) {
            // See https://en.wikipedia.org/wiki/Cubic_Hermite_spline
            // We use the unit interval -- endpoints are fixed at 0 and 1.
            return t * (1.0 - t) * (1.0 - t) * dydt0
                + t*t * (t - 1.0) * dydt1
                + t*t * (3.0 - 2.0 * t);
        }

        vec2 quad_spline(float t, vec2 cp0, vec2 cp1, vec2 cp2) {
            float a = 1.0 - t;
            float b = t;
            vec2 p = (a * a) * cp0 + (a * b) * cp1 + (b * b) * cp2;
            return p;
        }

        void main() {
            // The page shape is defined by a quadratic spline, with three control points.
            // When resting open, the control points follow Pythagorean triple 5 / 12 / 13,
            // the hypotenuse lying flat along the book surface. When moving the page:
            // - Control point 0 stays at 0,0
            // - Control point 1 rotates through a small angle, at distance 5/13 from point 0.
            // - Control point 2 rotates through 180 degrees, at distance 12/13 from point 1.
            // The arc length isn't constant through the whole range (for example, it's 18/12
            // when opened by 90 degrees), but we compensate for this by squashing along the
            // z-axis slightly.
            // We refer to the line between control points 0-1 as "spine", and 1-2 as "page".
            float kSpineLength = 5.0 / 13.0;
            float kPageLength = 12.0 / 13.0;
            float kRestingAngle = atan(kPageLength, kSpineLength);

            const float kPi = 3.14159265359;

            // Page position: 0 = on right hand side, 1 = fully rotated to left.
            float spineAngle = mix(kRestingAngle, kPi - kRestingAngle, pagePos);
            float pageAngle = kPi * smoothstep(0.0, 1.0, pagePos) + spineAngle - kPi/2.0;

            vec2 cp0 = vec2(0.0, 0.0);
            vec2 cp1 = cp0 + kSpineLength * vec2(cos(spineAngle), sin(spineAngle));
            vec2 cp2 = cp1 + kPageLength * vec2(cos(pageAngle), sin(pageAngle));

            // Now we have our control points, calculate the position of this mesh point.
            // Unfortunately the mesh will be distorted, as the arc length per time step
            // varies over the quadratic spline. To undo the distortion, we use a cubic
            // hermite spline (allowing us to specify the derivative at each endpoint).
            float k = 4.0 * pos.x * (1.0 - pos.x); // 0 at endpoints, 1 in the middle.
            float dt0 = mix(2.0, 1.8, k); // These derivatives are just hacks,
            float dt1 = mix(0.5, 0.6, k); // but they look about right.
            float t = cubic_hermite_spline(pos.x, dt0, dt1);

            vec2 p = quad_spline(t, cp0, cp1, cp2);

            float z = 1.0 - 0.2 * p.y;
            float x = p.x;
            float y = (2.0 * pos.y - 1.0);

            gl_Position = transform * vec4(x, y, 0.0, z);
            _texCoord = vec2(mix(pos.x, 1.0  - pos.x, pageFlip), pos.y);
        }
    );

    static const char* kFragment = AP_SHADER(
        varying vec2 _texCoord;
        uniform float alpha;
        uniform sampler2D tex;
        void main() {
            vec3 rgb = TEXTURE_2D_BIAS(tex, _texCoord, -0.25).rgb;
            vec4 rgba = vec4(rgb, alpha);
            OUTPUT(rgba);
        }
    );

    static AP_GLProgram* s_prog;
    static GLint s_transform;
    static GLint s_pagePos;
    static GLint s_pageFlip;
    static GLint s_alpha;
    static GLint s_texture;
    static GLint s_pos;

    static AP_GLBuffer* s_vbo;
    static AP_GLBuffer* s_ibo;

    const int kSegmentsX = 32;
    const int kSegmentsY = 2;

    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        s_prog = [[AP_GLProgram alloc] initWithVertex:kVertex fragment:kFragment];
        s_transform = [s_prog uniform:@"transform"];
        s_pagePos = [s_prog uniform:@"pagePos"];
        s_pageFlip = [s_prog uniform:@"pageFlip"];
        s_alpha = [s_prog uniform:@"alpha"];
        s_texture = [s_prog uniform:@"tex"];
        s_pos = [s_prog attr:@"pos"];

        GLfloat vertices[2 * kSegmentsX * kSegmentsY];
        GLfloat* vPtr = vertices;
        for (int i = 0; i < kSegmentsY; ++i) {
            float y = i / (float) (kSegmentsY - 1);
            for (int j = 0; j < kSegmentsX; ++j) {
                float x = j / (float) (kSegmentsX - 1);
                *vPtr++ = x;
                *vPtr++ = y;
            }
        }
        
        GLushort indices[6 * (kSegmentsX -1) * (kSegmentsY - 1)];
        GLushort* iPtr = indices;
#define indexAt(x,y) ((y)*kSegmentsX + (x))
        for (int i = 0; i < kSegmentsX-1; ++i) {
            for (int j = 0; j < kSegmentsY-1; ++j) {
                *iPtr++ = indexAt(i, j);
                *iPtr++ = indexAt(i+1, j);
                *iPtr++ = indexAt(i, j+1);
                *iPtr++ = indexAt(i+1, j+1);
                *iPtr++ = indexAt(i+1, j);
                *iPtr++ = indexAt(i, j+1);
            }
        }

        s_ibo = [AP_GLBuffer bufferWithTarget:GL_ELEMENT_ARRAY_BUFFER usage:GL_STATIC_DRAW data:indices size:sizeof(indices)];
        s_vbo = [AP_GLBuffer bufferWithTarget:GL_ARRAY_BUFFER usage:GL_STATIC_DRAW data:vertices size:sizeof(vertices)];
    }

    CGSize size = self.bounds.size;
    CGAffineTransform t = CGAffineTransformTranslate(
        CGAffineTransformScale(boundsToGL, size.width / 2, size.height / 2),
        1, 1);

    GLKMatrix4 matrix = GLKMatrix4Make(
        t.a,  t.b,  0, 0,
        t.c,  t.d,  0, 0,
        0,    0,    1, 0,
        t.tx, t.ty, 0, 1);

    AP_CHECK(s_prog, return);
    [s_prog use];

    [s_ibo bind];
    [s_vbo bind];
    _GL(EnableVertexAttribArray, s_pos);

    _GL(Uniform1f, s_alpha, alpha);
    _GL(VertexAttribPointer, s_pos, 2, GL_FLOAT, false, 8, 0);

    _GL(ActiveTexture, GL_TEXTURE0);
    _GL(Uniform1i, s_texture, 0);
    _GL(UniformMatrix4fv, s_transform, 1, false, matrix.m);

    // Draw left-hand pages
    _GL(Uniform1f, s_pageFlip, 1.0);
    int firstLeftPage = 0;
    for (int i = 2; i < _pageCount; i += 2) {
        if (_pos[i] >= 1) {
            firstLeftPage = i;
        } else {
            break;
        }
    }
    for (int i = firstLeftPage; i < _pageCount && _pos[i] > 0.5; i += 2) {
        AP_GLTexture* t = [_delegate textureForPage:i leftSide:YES];
        if (!t) {
            NSLog(@"*** No texture for left page %d", i);
            continue;
        }
        [t bind];
        _GL(Uniform1f, s_pagePos, AP_Ease(_pos[i]));
        _GL(DrawElements, GL_TRIANGLES, 6 * (kSegmentsX - 1) * (kSegmentsY - 1), GL_UNSIGNED_SHORT, 0);
    }

    // Draw right-hand pages in reverse order
    _GL(Uniform1f, s_pageFlip, 0.0);
    int lastRightPage = (_pageCount & ~1) - 1;
    for (int i = lastRightPage - 2; i >= 0; i -= 2) {
        if (_pos[i] <= 0) {
            lastRightPage = i;
        } else {
            break;
        }
    }
    for (int i = lastRightPage; i >= 0 && _pos[i] < 0.5; i -= 2) {
        AP_GLTexture* t = [_delegate textureForPage:i leftSide:NO];
        if (!t) {
            NSLog(@"*** No texture for right page %d", i);
            continue;
        }
        [t bind];
        _GL(Uniform1f, s_pagePos, AP_Ease(_pos[i]));
        _GL(DrawElements, GL_TRIANGLES, 6 * (kSegmentsX - 1) * (kSegmentsY - 1), GL_UNSIGNED_SHORT, 0);
    }

    _GL(DisableVertexAttribArray, s_pos);

    [s_ibo unbind];
    [s_vbo unbind];
}

@end
