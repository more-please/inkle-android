#import "AP_Profiler.h"
#import "AP_Utils.h"

#import <limits.h>

@interface AP_Profiler_Stat : NSObject
@property(nonatomic) double min;
@property(nonatomic) double max;
@property(nonatomic) double total;
@property(nonatomic) int count;
- (void) update:(double)value;
- (void) zero;
@end

@implementation AP_Profiler_Stat
- (id) init
{
    self = [super init];
    if (self) {
        [self zero];
    }
    return self;
}

- (void) zero
{
    _total = 0;
    _count = 0;
    _min = DBL_MAX;
    _max = DBL_MIN;
}

- (void) update:(double)value
{
    _total += value;
    _count++;
    _min = MIN(value, _min);
    _max = MAX(value, _max);
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"mean:%7.2f min:%7.2f max:%7.2f",
        1000 * (_total / _count), 1000 * _min, 1000 * _max];
}
@end

@implementation AP_Profiler {
    NSString* _stepName;
    double _stepStart;
    NSMutableDictionary* _stats;
    double _lastReportTime;
}

- (id) init
{
    self = [super init];
    if (self) {
        _stats = [NSMutableDictionary dictionary];
        _lastReportTime = AP_TimeInSeconds();
    }
    return self;
}

- (void) step:(NSString*)step
{
    if (_stepName) {
        [self end];
    }
    _stepName = step;
    _stepStart = AP_TimeInSeconds();
}

- (void) end
{
    if (_stepName) {
        double delta = AP_TimeInSeconds() - _stepStart;
        AP_Profiler_Stat* stat = [_stats objectForKey:_stepName];
        if (!stat) {
            stat = [[AP_Profiler_Stat alloc] init];
            [_stats setObject:stat forKey:_stepName];
        }
        [stat update:delta];
        _stepName = nil;
    }
}

- (void) maybeReport
{
    [self end];
    double t = AP_TimeInSeconds();
    if (_reportInterval > 0 && (t - _lastReportTime) > _reportInterval) {
        _lastReportTime = t;
        for (NSString* step in _stats) {
            AP_Profiler_Stat* stat = [_stats objectForKey:step];
            NSLog(@"| %@%@", [step stringByPaddingToLength:12 withString:@" " startingAtIndex:0], stat);
            [stat zero];
        }
    }
}

@end
