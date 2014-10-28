#pragma once

#import <Foundation/Foundation.h>

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

- (id) initWithResource:(NSString*)resource;

- (BOOL) prepareToPlay;
- (BOOL) play;
- (void) pause;
- (void) stop;

@end
