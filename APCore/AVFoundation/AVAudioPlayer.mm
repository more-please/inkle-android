
#import "AVAudioPlayer.h"

#import <ck/ck.h>
#import <ck/sound.h>
#import <PAK/PAK.h>

// Argh, hack
#import "../APKit/include/APKit/AP_UserDefaults.h"

#import "GlueCommon.h"

extern "C" {
NSString* const AP_UserDefault_Mute = @"AP_UserDefault_Mute";
}

@implementation AVAudioPlayer {
    NSString* _name;
    CkSound* _sound;
    NSTimer* _timer;
    float _volume;
}

- (id) initWithResource:(NSString*)path error:(NSError**)err
{
    self = [super init];
    if (self) {
        // Audio file type is always .cks
        path = [[path stringByDeletingPathExtension] stringByAppendingString:@".cks"];
        _name = [path lastPathComponent];
        _sound = CkSound::newStreamSound([path UTF8String], kCkPathType_FileSystem);
        _volume = 1.0;
        if (!_sound || _sound->isFailed()) {
            return nil;
        }
    }
    return self;
}

- (void) dealloc
{
    if (_sound) {
        _sound->destroy();
    }
}

- (NSTimeInterval) duration
{
    return 1000 * _sound->getLengthMs();
}

- (float) pan
{
    return _sound->getPan();
}

- (void) setPan:(float)pan
{
    _sound->setPan(pan);
}

- (float) volume
{
    return _volume;
}

- (void) setVolume:(float)volume
{
    _volume = volume;
    [self updateVolume];
}

- (void) updateVolume
{
    BOOL mute = [[AP_UserDefaults standardUserDefaults] boolForKey:AP_UserDefault_Mute];
    _sound->setVolume(mute ? 0.0 : _volume);
}

- (void) setNumberOfLoops:(int)i
{
    _numberOfLoops = i;
    _sound->setLoopCount(i);
}

- (BOOL) prepareToPlay
{
    return YES;
}

- (BOOL) isPlaying
{
    return _timer != nil;
}

- (BOOL) play
{
    if (!_timer) {
//        NSLog(@"+++ %@", _name);
        if (_sound->isReady()) {
            [self updateVolume];
            // Cricket resets the loop count after loading the audio file.
            _sound->setLoopCount(_numberOfLoops);
            _sound->play();
            _timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(playingTimer:) userInfo:nil repeats:YES];
        } else {
            _timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(loadingTimer:) userInfo:nil repeats:YES];
        }
    }
    return YES;
}

- (void) loadingTimer:(NSTimer*)timer
{
    if (_sound->isFailed()) {
        [_timer invalidate];
        _timer = nil;
        [_delegate audioPlayerDidFinishPlaying:self successfully:NO];
    } else if (_sound->isReady()) {
        [_timer invalidate];
        _timer = nil;
        [self play];
    } else {
        // Still loading...
    }
}

- (void) playingTimer:(NSTimer*)timer
{
    if (_sound->isFailed()) {
//        NSLog(@"xxx %@", _name);
        [_timer invalidate];
        _timer = nil;
        [_delegate audioPlayerDidFinishPlaying:self successfully:NO];
    } else if (_sound->isReady() && !_sound->isPlaying()) {
//        NSLog(@"--- %@", _name);
        [_timer invalidate];
        _timer = nil;
        [_delegate audioPlayerDidFinishPlaying:self successfully:YES];
    } else {
        // Still playing...
        [self updateVolume];
    }
}

- (void) pause
{
//    NSLog(@"... %@", _name);
    _sound->setPaused(true);
}

- (void) stop
{
//    NSLog(@"||| %@", _name);
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    _sound->stop();
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"[AVAudioPlayer %@]", _name];
}

@end
