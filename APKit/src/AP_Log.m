#import "AP_Log.h"

#import <stdarg.h>

static void logv(const char* file, int line, const char* format, va_list args)
{
    NSString* fmt = [NSString stringWithUTF8String:format];
    NSString* err = [[NSString alloc] initWithFormat:fmt arguments:args];
    NSLog(@"%s:%d %@", file, line, err);
}

void AP_LogError_(const char* file, int line, const char* format, ...)
{
    va_list args;
    va_start(args, format);
    logv(file, line, format, args);
    va_end(args);
}

void AP_LogFatal_(const char* file, int line, const char* format, ...)
{
    va_list args;
    va_start(args, format);
    logv(file, line, format, args);
    va_end(args);

    abort();
}
