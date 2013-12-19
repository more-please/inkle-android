#import "AP_Animation.h"

#import "AP_Check.h"
#import "AP_Utils.h"
#import "AP_View.h"
#import "NSObject+AP_KeepAlive.h"

#ifdef ANDROID
NSTimeInterval CACurrentMediaTime() {
    return [AP_Animation masterClock];
}
#endif

@implementation AP_Animation {
    double _creationTime;
    BOOL _startTimeWasAdjusted;
    double _startTime;
    double _finishTime;
    double _progress;
    BOOL _reverse;
    void (^_completion)(BOOL finished);
    NSMutableArray* _views;
    BOOL _alreadyFinished;
}

static NSMutableArray* g_Animations;
static double g_MasterClock;

+ (void)initialize
{
    static BOOL initialized = NO;
    if (!initialized)
    {
        initialized = YES;
        g_Animations = [NSMutableArray array];
    }
}

+ (NSArray*) animations
{
    return [NSArray arrayWithArray:g_Animations];
}

+ (NSTimeInterval) masterClock
{
    return g_MasterClock;
}

+ (void) setMasterClock:(NSTimeInterval)time
{
    g_MasterClock = time;
}

AP_BAN_EVIL_INIT;

- (id) initWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options completion:(void (^)(BOOL finished))completion
{
    self = [super init];
    if (self) {
        double t = g_MasterClock;
        _creationTime = t;
        _startTimeWasAdjusted = NO;

        _startTime = t + delay;
        _finishTime = _startTime + duration;
        _progress = 0;
        _options = options;
        _reverse = NO;
        _completion = completion;
        _views = [NSMutableArray array];

        [g_Animations addObject:self];
    }
    return self;
}

- (void) addView:(AP_View *)view
{
    if (_tag) {
        NSLog(@"Adding view: %@ to animation: %@", view, _tag);
    }

    [_views addObject:view];
}

- (void) removeView:(AP_View *)view
{
    if (_tag) {
        NSLog(@"Removing view: %@ from animation: %@", view, _tag);
    }

    [_views removeObject:view];
    if ([_views count] == 0) {
        [self cancel];
    }
}

- (void) update
{
    double t = g_MasterClock;

    // Pretend the animation started just as this frame is displayed,
    // to hide any pauses caused by texture loading etc.
    if (!_startTimeWasAdjusted) {
        _startTimeWasAdjusted = YES;
        double fudge = (t - _creationTime);
        _startTime += fudge;
        _finishTime += fudge;
    }

    if (_options & UIViewAnimationOptionRepeat) {
        double duration = _finishTime - _startTime;
        while (t >= _finishTime) {
            _startTime += duration;
            _finishTime += duration;
            if (_options & UIViewAnimationOptionAutoreverse) {
                _reverse = !_reverse;
            }
        }
    }

    if (t >= _finishTime || _finishTime <= _startTime) {
        _progress = 1;
    } else if (t <= _startTime) {
        _progress = 0;
    } else {
        _progress = (t - _startTime) / (_finishTime - _startTime);
        _progress = AP_Ease(_progress);
    }

    if (_reverse) {
        _progress = 1 - _progress;
    }

    if (_tag) {
        NSLog(@"Updating animation: %@ (progress: %.1f)", _tag, _progress);
    }

    if (t >= _finishTime) {
        [self finish];
    }
}

- (CGFloat) progress
{
    return _progress;
}

- (void) cancel
{
    if (_tag) {
        NSLog(@"Cancelling animation: %@", _tag);
    }
    if (_alreadyFinished) {
        AP_LogFatal("Animation finished twice!");
        return;
    }
    _alreadyFinished = YES;
    
    [self keepAliveForTimeInterval:0.1];
    AP_Animation* protectSelf = self;

    [g_Animations removeObject:self];

    NSMutableArray* views = _views.mutableCopy;
    _views = nil;
    for (AP_View* view in views) {
        [view animationWasCancelled];
    }

    if (protectSelf->_completion) {
        protectSelf->_completion(NO);
    }
}

- (void) finish
{
    if (_tag) {
        NSLog(@"Finishing animation: %@", _tag);
    }
    if (_alreadyFinished) {
        AP_LogFatal("Animation finished twice!");
        return;
    }
    _alreadyFinished = YES;
    
    [self keepAliveForTimeInterval:0.1];
    AP_Animation* protectSelf = self;

    [g_Animations removeObject:self];
    _progress = 1;

    NSMutableArray* views = _views.mutableCopy;
    _views = nil;
    for (AP_View* view in views) {
        [view animationWasFinished];
    }

    if (protectSelf->_completion) {
        protectSelf->_completion(YES);
    }
}

@end
