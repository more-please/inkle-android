#import "GAITracker.h"

#import <UIKit/UIScreen.h>
#import <SDL2/SDL.h>

#import "GAI.h"
#import "GAIFields.h"

@implementation AP_GAITracker {
    NSMutableDictionary* _params;
    BOOL _sessionStarted;
}

- (instancetype) initWithTrackingId:(NSString*)trackingId
{
    self = [super init];
    if (self) {
        _params = [NSMutableDictionary dictionary];
        _params[kGAITrackingId] = trackingId;
    }
    return self;
}

- (void) set:(NSString*)parameterName value:(NSString*)value
{
    _params[parameterName] = value;
}

- (void) send:(NSDictionary*)params
{
    NSMutableDictionary* p = [_params mutableCopy];
    [p addEntriesFromDictionary:params];

    if (!_sessionStarted) {
        _sessionStarted = YES;
        p[kGAISessionControl] = @"start";
    }

    CGSize size = [UIScreen mainScreen].bounds.size;
    p[kGAIViewportSize] = [NSString stringWithFormat:@"%dx%d", (int) size.width, (int) size.height];

    SDL_DisplayMode mode;
    SDL_GetCurrentDisplayMode(0, &mode);
    p[kGAIScreenResolution] = [NSString stringWithFormat:@"%dx%d", mode.w, mode.h];

    p[kGAIDataSource] = @"app";

    [[GAI sharedInstance] send:p];
}

@end
