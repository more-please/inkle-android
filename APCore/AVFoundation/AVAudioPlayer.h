#pragma once

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

// If set to YES, audio should be muted.
extern NSString* const AP_UserDefault_Mute;

#ifdef __cplusplus
} // extern "C"
#endif

@class AVAudioPlayer;

@protocol AVAudioPlayerDelegate <NSObject>
- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer*)player successfully:(BOOL)flag;
@end

@interface AVAudioPlayer : NSObject

@property(nonatomic,weak) id<AVAudioPlayerDelegate> delegate;
@property(nonatomic,readonly,getter=isPlaying) BOOL playing;
@property(nonatomic) NSTimeInterval currentTime;
@property(nonatomic) float pan;
@property(nonatomic) float volume;
@property(nonatomic) int numberOfLoops;
@property(nonatomic,readonly) NSTimeInterval duration;

- (id) initWithResource:(NSString*)resource error:(NSError**)err;

- (BOOL) prepareToPlay;
- (BOOL) play;
- (void) pause;
- (void) stop;

@end
