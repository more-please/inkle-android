#import "AP_BookView.h"

#import <GLKit/GLKit.h>

#import <vector>

#import "AP_Check.h"
#import "AP_GLBuffer.h"
#import "AP_GLProgram.h"
#import "AP_GLTexture.h"
#import "AP_Utils.h"
#import "AP_Touch.h"
#import "AP_ScrollView.h"

#ifdef SORCERY_SDL
#import <SDL2/SDL.h>
#endif

using namespace std;

@implementation AP_BookView {
    AP_ScrollView* _scrollView;
    __weak id<AP_BookViewDelegate> _delegate;
    int _pageCount;
    float _bookPos; // Fractional page number, tracks the scroll view position.
    float _bookPosLo; // Tracks low-water mark of bookPos, converges slowly.
    float _bookPosHi; // Tracks high-water mark of bookPos, converges slowly.
    AP_TapGestureRecognizer* _tapGesture;
}

- (instancetype) initWithPageCount:(int)pageCount delegate:(id<AP_BookViewDelegate>)delegate frame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _delegate = delegate;
        _pageCount = pageCount;

        _scrollView = [[AP_ScrollView alloc] initWithFrame:self.bounds];
        _scrollView.pagingEnabled = YES;
        _scrollView.horizontal = YES;
        [self addSubview:_scrollView];
        [self layoutSubviews];

        _tapGesture = [[AP_TapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)];
        [self addGestureRecognizer:_tapGesture];
    }
    return self;
}

- (AP_View*) hitTest:(CGPoint) point withEvent:(AP_Event *)event {
    if ([self pointInside:point withEvent:event]) {
        // Send all touches to scroll view
        return _scrollView;
    }
    return nil;
}

- (void) layoutSubviews
{
    CGRect r = self.bounds;
    r.size.width /= 2;
    r.origin.x += r.size.width;
    _scrollView.frame = r;
    _scrollView.contentSize = CGSizeMake((_pageCount + 1) / 2 * r.size.width, r.size.height);
}

- (int) currentPage
{
    return _scrollView.pageIndex * 2;
}

- (void) setCurrentPage:(int)i animated:(BOOL)animated
{
    if (animated) {
        [AP_View animateWithDuration:0.5 delay:0
            options:UIViewAnimationOptions(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState)
            animations:^{
                _scrollView.pageIndex = i / 2;
            }
            completion:nil
        ];
    } else {
        _scrollView.pageIndex = i / 2;
        _bookPos = (_scrollView.contentOffset.x / _scrollView.bounds.size.width);
        _bookPosLo = _bookPos;
        _bookPosHi = _bookPos + 1;
    }
}

- (void) tap
{
    CGPoint pos = [_tapGesture locationInView:self];
    int oldPage = self.currentPage;
    int newPage = AP_CLAMP(oldPage + (pos.x < self.bounds.size.width / 2 ? -2 : 2), 0, _pageCount - 1);
    [self setCurrentPage:newPage animated:YES];
    [self.window resetAllGestures];
}

- (void) scrollViewDidScroll:(AP_ScrollView *)scrollView
{
    [self setNeedsDisplay];
}

- (void) updateGL:(float)dt
{
    float oldBookPos = _bookPos;
    float oldBookPosHi = _bookPosHi;
    float oldBookPosLo = _bookPosLo;

    _bookPos = (_scrollView.inFlightBounds.origin.x / _scrollView.bounds.size.width);

    const float kStandardFrameTime = 1.0/30.0;
    const float kDamping = 0.2;

    float frames = AP_CLAMP(dt / kStandardFrameTime, 0.1, 10);
    float k = 1 - powf(1 - kDamping, frames);
    _bookPosLo = MIN(_bookPos, AP_Lerp(_bookPosLo, _bookPos, k));
    _bookPosHi = MAX(_bookPos + 1, AP_Lerp(_bookPosHi, _bookPos + 1, k));

    if (oldBookPos != _bookPos
     || oldBookPosHi != _bookPosHi
     || oldBookPosLo != _bookPosLo)
    {
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
                *iPtr++ = indexAt(i, j+1);
                *iPtr++ = indexAt(i+1, j+1);
                *iPtr++ = indexAt(i+1, j);
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

    // Pages up to _bookPosLo should have position 1 (full left)
    // Pages from _bookPosHi up should have position 0 (full right)
    // Pages in between should have fractional positions.
    vector<float> pagePos(_pageCount);
    for (int i = 0; i < _pageCount; ++i) {
        // Page position 0 = full right, 1 = full left
        // If bookPos=0, page positions should be: 1, 0, 0 etc
        // If bookPos=1, page positions should be: 1, 1, 0 etc
        int physicalPage = (i + 1) / 2;
        float t = (physicalPage - _bookPosLo) / (_bookPosHi - _bookPosLo);
        pagePos[i] = AP_CLAMP(1 - t, 0, 1);
    }

    // Draw left-hand pages
    _GL(Uniform1f, s_pageFlip, 1.0);
    int firstLeftPage = 2;
    for (int i = firstLeftPage + 2; i < _pageCount; i += 2) {
        if (pagePos[i] >= 1) {
            firstLeftPage = i;
        } else {
            break;
        }
    }
    for (int i = firstLeftPage - 2; i < _pageCount && pagePos[i] > 0.5; i += 2) {
        AP_GLTexture* t = [_delegate textureForPage:i leftSide:YES];
        if (!t) {
            NSLog(@"*** No texture for left page %d", i);
            continue;
        }
        [t bind];
        _GL(Uniform1f, s_pagePos, pagePos[i]);
        _GL(DrawElements, GL_TRIANGLES, 6 * (kSegmentsX - 1) * (kSegmentsY - 1), GL_UNSIGNED_SHORT, 0);
    }

    // Draw right-hand pages in reverse order
    _GL(Uniform1f, s_pageFlip, 0.0);
    int lastRightPage = (_pageCount & ~1) - 3;
    for (int i = lastRightPage - 2; i >= 0; i -= 2) {
        if (pagePos[i] <= 0) {
            lastRightPage = i;
        } else {
            break;
        }
    }
    for (int i = lastRightPage + 2; i >= 0 && pagePos[i] < 0.5; i -= 2) {
        AP_GLTexture* t = [_delegate textureForPage:i leftSide:NO];
        if (!t) {
            NSLog(@"*** No texture for right page %d", i);
            continue;
        }
        [t bind];
        _GL(Uniform1f, s_pagePos, pagePos[i]);
        _GL(DrawElements, GL_TRIANGLES, 6 * (kSegmentsX - 1) * (kSegmentsY - 1), GL_UNSIGNED_SHORT, 0);
    }

    _GL(DisableVertexAttribArray, s_pos);

    [s_ibo unbind];
    [s_vbo unbind];
}

@end
