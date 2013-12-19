#import "AP_PakReader.h"

#import <fcntl.h>
#import <sys/mman.h>

#import "AP_Check.h"

@implementation AP_PakReader {
    NSData* _data;
    BOOL _isMemoryMapped;
    NSMutableDictionary* _files;
}

- (AP_PakReader*) initWithData:(NSData *)data {
    self = [super init];
    if (self) {
        _data = data;
        _isMemoryMapped = NO;

        AP_CHECK_GE(_data.length, 16, return nil);
        AP_CHECK_EQ(memcmp(_data.bytes, "AP_Pack!", 8), 0, return nil);

        uint32_t totalSize = [self wordAtOffset:8];
        uint32_t dirOffset = [self wordAtOffset:12];

        AP_CHECK_EQ(data.length, totalSize, return nil);
        AP_CHECK_EQ(totalSize & 15, 0, return nil);
        AP_CHECK_EQ(dirOffset & 15, 0, return nil);
        AP_CHECK_GE(totalSize, dirOffset, return nil);

        uint32_t dirSize = (totalSize - dirOffset) / 16;
        _files = [NSMutableDictionary dictionaryWithCapacity:dirSize];
        for (uint32_t entryPos = dirOffset; entryPos < totalSize; entryPos += 16) {
            NSString* entryName = [[NSString alloc] initWithData:[self blob:entryPos] encoding:NSUTF8StringEncoding];
            NSData* entryData = [self blob:(entryPos + 8)];
            _files[entryName] = entryData;
        }
    }
    return self;
}

- (void) dealloc
{
    if (_isMemoryMapped) {
        int result = munmap((void*) [_data bytes], [_data length]);
        if (result != 0) {
            AP_LogError("munmap() failed! %s", strerror(errno));
        }
    }
}

- (NSData*) blob:(uint32_t)blobOffset {
    char* base = (char*)[_data bytes];
    uint32_t offset = [self wordAtOffset:(blobOffset)];
    uint32_t size = [self wordAtOffset:(blobOffset + 4)];
    // subdataWithRange copies the data, bah! So let's use dataWithBytesNoCopy.
    // This should be safe as long as the AP_PakReader itself is still alive.
    return [NSData dataWithBytesNoCopy:(base + offset) length:size freeWhenDone:NO];
}

- (uint32_t) wordAtOffset:(uint32_t)offset {
    assert((offset & 3) == 0);
    const uint32_t* ptr = (const uint32_t*) _data.bytes;
    return ptr[offset / 4];
}

- (NSData*) getFile:(NSString*)filename {
    NSData* result = [_files objectForKey:filename];
    return result;
}

+ (AP_PakReader*) readerWithData:(NSData *)data
{
    return [[AP_PakReader alloc] initWithData:data];
}

+ (AP_PakReader*) readerWithMemoryMappedFile:(NSString *)filename
{
    AP_PakReader* result = nil;
    int fd = open([filename UTF8String], O_RDONLY);
    if (fd > 0) {
        long size = lseek(fd, 0, SEEK_END);
        if (size > 0) {
            uint8_t* ptr = mmap(0, size, PROT_READ, MAP_PRIVATE, fd, 0);
            if (ptr != MAP_FAILED) {
                NSData* data = [NSData dataWithBytesNoCopy:ptr length:size freeWhenDone:NO];
                result = [[AP_PakReader alloc] initWithData:data];
                result->_isMemoryMapped = YES;
            }
        }
    }
    close(fd);
    if (result) {
        NSLog(@"Loaded expansion file: %@", filename);
    } else {
        NSLog(@"Failed to load expansion file: %s", strerror(errno));
    }
    return result;
}

@end