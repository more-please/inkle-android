#import "UIApplication.h"

#import "GlueCommon.h"

#import <Foundation/Foundation.h>

#import <stdlib.h>
#import <stdio.h>

@implementation UIApplication

static UIApplication* g_Application;

+ (UIApplication*) sharedApplication
{
    return g_Application;
}

- (BOOL) needsInitialSetup
{
    return NO;
}

- (BOOL) isFullScreen
{
    GLUE_NOT_IMPLEMENTED;
    return NO;
}

- (void) setFullScreen:(BOOL)fullScreen
{
    GLUE_NOT_IMPLEMENTED;
}

- (NSString*) versionName
{
    GLUE_NOT_IMPLEMENTED;
    return @"VERSION_NAME";
}

- (NSString*) googleAnalyticsId
{
    GLUE_NOT_IMPLEMENTED;
    return @"GOOGLE_ANALYTICS_ID";
}

- (id) init
{
    self = [super init];
    if (self) {
        NSAssert(!g_Application, @"Tried to init UIApplication twice");
        g_Application = self;
    }
    return self;
}

- (BOOL) canTweet
{
    GLUE_NOT_IMPLEMENTED;
    return NO;
}

- (void) tweet:(NSString*)text url:(NSString*)url image:(NSString*)image
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) shareJourneyWithName:(NSString*)existingName block:(NameResultBlock)block
{
    GLUE_NOT_IMPLEMENTED;
    block(nil);
}

- (void) mailTo:(NSString*)to message:(NSString*)message attachment:(NSString*)path
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) quit
{
    GLUE_NOT_IMPLEMENTED;
    exit(EXIT_SUCCESS);
}

- (void) lockQuit
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) unlockQuit
{
    GLUE_NOT_IMPLEMENTED;
}

- (void) fatalError:(NSString*)message
{
    GLUE_NOT_IMPLEMENTED;
    fprintf(stderr, "FATAL ERROR: %s\n", message.UTF8String);
    abort();
}

- (BOOL) isPartInstalled:(int)part
{
    GLUE_NOT_IMPLEMENTED;
    return NO;
}

- (void) openPart:(int)part
{
    GLUE_NOT_IMPLEMENTED;
}

@end
