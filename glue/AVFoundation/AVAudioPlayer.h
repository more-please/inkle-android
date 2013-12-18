#pragma once

#import <Foundation/Foundation.h>

@protocol AVAudioPlayerDelegate <NSObject>
@end

@interface AVAudioPlayer : NSObject

@property(nonatomic,assign) id<AVAudioPlayerDelegate> delegate;
@property(nonatomic,readonly,getter=isPlaying) BOOL playing; /* is it playing or not? */
@property(nonatomic) NSTimeInterval currentTime;
@property(nonatomic) BOOL enableRate;
@property(nonatomic) float rate;
@property(nonatomic) float pan;
@property(nonatomic) float volume;
@property(nonatomic) NSInteger numberOfLoops;

- (id) initWithContentsOfURL:(NSURL*)url error:(NSError**)outError;

- (BOOL) prepareToPlay;
- (BOOL) play;
- (void) pause;
- (void) stop;

@end
