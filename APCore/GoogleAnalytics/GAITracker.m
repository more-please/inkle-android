#import "GAITracker.h"

#import <UIKit/UIScreen.h>
#import <SDL2/SDL.h>

#import "GAI.h"
#import "GAIFields.h"

@implementation AP_GAITracker {
    NSMutableDictionary* _params;
    NSMutableDictionary* _onceParams;
}

- (instancetype) initWithTrackingId:(NSString*)trackingId
{
    self = [super init];
    if (self) {
        _params = [NSMutableDictionary dictionary];
        _onceParams = [NSMutableDictionary dictionary];
        _params[kGAITrackingId] = trackingId;
    }
    return self;
}

- (void) set:(NSString*)parameterName value:(NSString*)value
{
    if (!value) {
        [_params removeObjectForKey:parameterName];
        return;
    }

    _params[parameterName] = value;

    if ([parameterName isEqualToString:kGAIScreenName] && value) {
        [self send:@{
            kGAIHitType: @"screenview",
        }];
    }
}

- (void) setOnce:(NSString *)parameterName value:(NSString *)value
{
    _onceParams[parameterName] = value;
}

- (void) send:(NSDictionary*)params
{
    NSMutableDictionary* p = _onceParams;
    _onceParams = [NSMutableDictionary dictionary];

    [p addEntriesFromDictionary:_params];
    [p addEntriesFromDictionary:params];

    CGSize size = [UIScreen mainScreen].bounds.size;
    p[kGAIViewportSize] = [NSString stringWithFormat:@"%dx%d", (int) size.width, (int) size.height];

    SDL_DisplayMode mode;
    SDL_GetCurrentDisplayMode(0, &mode);
    p[kGAIScreenResolution] = [NSString stringWithFormat:@"%dx%d", mode.w, mode.h];

    p[kGAIDataSource] = @"app";

    [[GAI sharedInstance] send:p];
}

@end
