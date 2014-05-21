#import "AP_ActivityIndicatorView.h"

#import "AP_ImageView.h"

@implementation AP_ActivityIndicatorView {
    AP_ImageView* _inner;
    AP_ImageView* _outer;
    CGFloat _innerAngle;
    CGFloat _outerAngle;
}

- (id) initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyle)style
{
    CGRect r = {0, 0, 32, 32};
    self = [super initWithFrame:r];
    if (self) {
        _inner = [[AP_ImageView alloc] initWithFrame:r];
        _outer = [[AP_ImageView alloc] initWithFrame:r];
        
        _inner.image = [AP_Image imageNamed:@"spinner_inner.png"];
        _outer.image = [AP_Image imageNamed:@"spinner_outer.png"];

        _inner.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _outer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        _inner.contentMode = UIViewContentModeScaleAspectFill;
        _outer.contentMode = UIViewContentModeScaleAspectFill;

        [self addSubview:_inner];
        [self addSubview:_outer];
    }
    return self;
}

- (void) startAnimating
{
    _isAnimating = YES;
}

- (void) stopAnimating
{
    _isAnimating = NO;
}

- (void) updateGL:(float)timeStep
{
    [super updateGL:timeStep];

    if (_isAnimating) {
        float phi = (1 + sqrtf(5)) / 2;
        _innerAngle += 2 * timeStep * phi;
        _outerAngle -= 2 * timeStep;
        _inner.transform = CGAffineTransformMakeRotation(_innerAngle);
        _outer.transform = CGAffineTransformMakeRotation(_outerAngle);
    }
}

@end
