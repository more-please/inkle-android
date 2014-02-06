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
@property(nonatomic) BOOL enableRate;
@property(nonatomic) float rate;
@property(nonatomic) float pan;
@property(nonatomic) float volume;
@property(nonatomic) NSInteger numberOfLoops;

- (id) initWithContentsOfURL:(NSURL*)url error:(NSError**)outError;
- (id) initWithContentsOfFile:(NSString*)path error:(NSError**)outError;

- (BOOL) prepareToPlay;
- (BOOL) play;
- (void) pause;
- (void) stop;

@end
