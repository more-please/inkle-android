#import "AP_FileUtils.h"

#import <zlib.h>

#ifdef ANDROID
#include <dirent.h>
#include <fcntl.h>
#include <unistd.h>
#endif

#ifdef WINDOWS

#include <io.h>
#include <fcntl.h>
#include <shlobj.h>
#include <sys/stat.h>

// For heaven's sake Microsoft, open() is perfectly fine
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#define open _open
#define close _close
#define write _write
#define fsync(fd) _flushall

#define O_CREAT _O_CREAT
#define O_WRONLY _O_WRONLY
#define O_APPEND _O_APPEND
#define S_IRUSR _S_IREAD
#define S_IWUSR _S_IWRITE
#define S_IRGRP _S_IREAD
#define S_IROTH _S_IREAD

#endif

#ifdef WINDOWS
static NSString* getLastWindowsError() {
    DWORD err = GetLastError();
    static char buffer[1000];
    int len = FormatMessage(
        FORMAT_MESSAGE_FROM_SYSTEM,
        NULL,
        err,
        LANG_NEUTRAL,
        buffer,
        999,
        NULL);
    if (len <= 0) {
        return nil;
    }
    buffer[len] = 0;
    return [NSString stringWithFormat:@"%s (code: %d)", buffer, (int)err];
}
#endif

void ffsync(NSString* path)
{
    int fd = open(path.UTF8String, O_RDONLY);
    if (fd < 0) {
        NSLog(@"open(%@) failed: %s", path, strerror(errno));
        return;
    }
    if (fsync(fd) < 0) {
        NSLog(@"fsync(%@) failed: %s", path, strerror(errno));
        // Continue anyway
    }
    if (close(fd) < 0) {
        NSLog(@"close(%@) failed: %s", path, strerror(errno));
        // Continue anyway
    }
}

NSArray* getDirectoryContents(NSString* dir)
{
#ifdef WINDOWS
    NSMutableArray* result = [NSMutableArray array];
    
    const uint16_t* wdir = [[NSFileManager defaultManager]
                            fileSystemRepresentationWithPath:[dir stringByAppendingPathComponent:@"*"]];
    int len = WideCharToMultiByte(CP_UTF8, 0, (const wchar_t*) wdir, -1, NULL, 0, NULL, NULL);
    char* cdir = (char*) calloc(len + 1, 1);
    WideCharToMultiByte(CP_UTF8, 0, (const wchar_t*) wdir, -1, cdir, len, NULL, NULL);
    
    WIN32_FIND_DATA data;
    HANDLE h = FindFirstFile(cdir, &data);
    free(cdir);
    
    if (h == INVALID_HANDLE_VALUE) {
        NSLog(@"*** Error reading directory %s: %@", cdir, getLastWindowsError());
    } else {
        do {
            NSString* s = [NSString stringWithUTF8String:data.cFileName];
            [result addObject:s];
        } while (FindNextFile(h, &data));
    }
#elif defined(ANDROID)
    NSMutableArray* result = [NSMutableArray array];
	DIR* d = opendir(dir.UTF8String);
	if (d) {
		for (struct dirent* e = readdir(d); e; e = readdir(d)) {
			NSString* f = [NSString stringWithFormat:@"%s", e->d_name];
			[result addObject:f];
		}
		closedir(d);
	} else {
		NSLog(@"Warning: opendir() failed on directory: %@ error: %s", dir, strerror(errno));
	}
	return result;
#else
    NSError* err;
    NSArray* result = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:&err];
    if (err) {
        NSLog(@"*** Error reading directory %@: %@", dir, err);
        return nil;
    }
#endif
    return result;
}

NSData* gzip(NSData* uncompressed)
{
    z_stream z;
    memset(&z, 0, sizeof(z));
    z.next_in = (unsigned char*) uncompressed.bytes;
    z.avail_in = (uInt) uncompressed.length;

    int zerr = deflateInit2(
        &z,
        Z_DEFAULT_COMPRESSION,
        Z_DEFLATED,
        31, // default 15 windowsbits + 16 for gzip format
        8, // suggested default memlevel
        Z_DEFAULT_STRATEGY
    );
    if (zerr != Z_OK) {
        NSLog(@"*** inflateInit failed! Error code: %d (%s)", zerr, z.msg);
        return nil;
    }

    NSMutableData* buffer = [NSMutableData dataWithLength:deflateBound(&z, uncompressed.length)];
    z.next_out = (unsigned char*) buffer.bytes;
    z.avail_out = (uInt) buffer.length;
    zerr = deflate(&z, Z_FINISH);
    if (zerr != Z_STREAM_END) {
        NSLog(@"*** deflate failed! Error code: %d (%s)", zerr, z.msg);
        return nil;
    }

    zerr = deflateEnd(&z);
    if (zerr != Z_OK) {
        NSLog(@"*** inflateEnd failed! Error code: %d (%s)", zerr, z.msg);
        return nil;
    }
    
    NSLog(@"Compressed %d bytes -> %d", (int) uncompressed.length, (int) z.total_out);
    [buffer setLength:z.total_out];
    return buffer;
}

NSData* gunzip(NSData* compressed)
{
    NSMutableArray* chunks = [NSMutableArray array];
    NSMutableData* buffer = [NSMutableData dataWithLength:16384];
    
    z_stream z;
    memset(&z, 0, sizeof(z));
    z.next_in = (unsigned char*) compressed.bytes;
    z.avail_in = (uInt) compressed.length;
    z.next_out = (unsigned char*) buffer.bytes;
    z.avail_out = (uInt) buffer.length;
    
    int zerr = inflateInit2(&z, 47); // default 15 windowsbits + 32 for format detection
    if (zerr != Z_OK) {
        NSLog(@"*** inflateInit failed! Error code: %d (%s)", zerr, z.msg);
        return nil;
    }
    
    while (zerr == Z_OK) {
        z.next_out = (unsigned char*) buffer.bytes;
        z.avail_out = (uInt) buffer.length;
        zerr = inflate(&z, Z_SYNC_FLUSH);
        NSData* chunk = [NSData dataWithBytes:buffer.bytes length:(buffer.length - z.avail_out)];
        [chunks addObject:chunk];
    }
    
    if (zerr != Z_STREAM_END) {
        NSLog(@"*** inflate failed! Error code: %d (%s)", zerr, z.msg);
        return nil;
    }
    
    zerr = inflateEnd(&z);
    if (zerr != Z_OK) {
        NSLog(@"*** inflateEnd failed! Error code: %d (%s)", zerr, z.msg);
        return nil;
    }
    
    NSLog(@"Decompressed %d bytes -> %d", (int) compressed.length, (int) z.total_out);
    NSMutableData* result = [NSMutableData dataWithCapacity:z.total_out];
    for (NSData* chunk in chunks) {
        [result appendData:chunk];
    }
    
    return result;
}

