#import "AVAudioPlayer.h"

#import <ck/ck.h>
#import <ck/sound.h>

#import "GlueCommon.h"

@implementation AVAudioPlayer {
    NSString* _name;
    CkSound* _sound;
    NSTimer* _timer;
}

- (id) initWithContentsOfURL:(NSURL*)url error:(NSError**)outError
{
    if (!url.isFileURL) {
        NSLog(@"Not a file URL: %@", url);
        return nil;
    }
    return [self initWithContentsOfFile:url.path error:outError];
}

- (id) initWithContentsOfFile:(NSString*)path error:(NSError**)outError
{
    self = [super init];
    if (self) {
        _name = [path lastPathComponent];
        _sound = CkSound::newStreamSound(path.cString, kCkPathType_FileSystem);
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

- (void) setEnableRate:(BOOL)enableRate
{
    _enableRate = enableRate;
    if (!enableRate) {
        _sound->setSpeed(1);
    }
}

- (float) rate
{
    return _sound->getSpeed();
}

- (void) setRate:(float)rate
{
    _sound->setSpeed(rate);
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
    return _sound->getVolume();
}

- (void) setVolume:(float)volume
{
    _sound->setVolume(volume);
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
