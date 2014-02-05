#import "AVAudioPlayer.h"

#import <ck/ck.h>
#import <ck/sound.h>

#import "GlueCommon.h"

@implementation AVAudioPlayer {
    NSString* _name;
    CkSound* _sound;
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
    NSLog(@"Loaded sound: %@", _name);
    return self;
}

- (void) dealloc
{
    NSLog(@"Deleted sound: %@", _name);
    if (_sound) {
        _sound->destroy();
    }
}

- (BOOL) isPlaying
{
    return _sound->isPlaying();
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

- (BOOL) play
{
    NSLog(@"Playing sound: %@, rate: %.3f, volume: %.3f", _name, _sound->getSpeed(), _sound->getVolume());
    _sound->play();
    _sound->setPaused(false);
    return YES;
}

- (void) pause
{
    _sound->setPaused(true);
}

- (void) stop
{
    _sound->stop();
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"[AVAudioPlayer %@]", _name];
}

@end
