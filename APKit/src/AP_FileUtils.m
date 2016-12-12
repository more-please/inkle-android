#import "AP_FileUtils.h"

#import <zlib.h>

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
    
    while (zerr != Z_STREAM_END) {
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

