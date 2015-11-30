#import "PAK.h"

#import <fcntl.h>
#import <sys/mman.h>
#import <zlib.h>

#ifdef WINDOWS

#include <io.h>

#define open _open
#define close _close
#define lseek _lseek

#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#endif

NSString* const PAK_SearchPathChangedNotification = @"PAK_SearchPathChangedNotification";

// ---------------------------------------------------------------------------------------

@implementation PAK_Item {
    NSData* _originalData;
    __weak NSData* _uncompressedData;
}

- (instancetype) initWithName:(NSString*)name length:(int)length data:(NSData*)data
{
	self = [super init];
	if (self) {
        _name = name;
        _isCompressed = (length != data.length);
		_length = length;
		_originalData = data;
	}
	return self;
}

- (NSData*) data
{
    if (!_isCompressed) {
        return _originalData;
    }
    NSData* result = _uncompressedData;
    if (!result) {
//        NSLog(@"Decompressing %@ (%d -> %d)", _name, _originalData.length, _length);
        result = [NSMutableData dataWithLength:_length];

        z_stream z;
        memset(&z, 0, sizeof(z));
        z.next_in = (unsigned char*)_originalData.bytes;
        z.avail_in = (uInt) _originalData.length;
        z.next_out = (unsigned char*)result.bytes;
        z.avail_out = (uInt) result.length;

        int zerr = inflateInit(&z);
        if (zerr != Z_OK) {
            NSLog(@"*** inflateInit failed! Error code: %d (%s)", zerr, z.msg);
            return nil;
        }

        zerr = inflate(&z, Z_FINISH);
        if (zerr != Z_STREAM_END) {
            NSLog(@"*** inflate failed! Error code: %d (%s)", zerr, z.msg);
            return nil;
        }

        zerr = inflateEnd(&z);
        if (zerr != Z_OK) {
            NSLog(@"*** inflateEnd failed! Error code: %d (%s)", zerr, z.msg);
            return nil;
        }

        _uncompressedData = result;
    }
    return result;
}

@end

// ---------------------------------------------------------------------------------------

@implementation PAK {
    BOOL _isMemoryMapped;
    NSDictionary* _items;
}

+ (PAK*) pakWithData:(NSData*)data
{
    return [[PAK alloc] initWithData:data];
}

+ (PAK*) pakWithMemoryMappedFile:(NSString*)filename
{
#ifdef OSX
    filename = [[NSBundle mainBundle] pathForResource:filename ofType:nil];
#endif
    PAK* result = nil;
    int fd = open([filename UTF8String], O_RDONLY);
    if (fd > 0) {
        long size = lseek(fd, 0, SEEK_END);
        if (size > 0) {
            uint8_t* ptr = mmap(0, size, PROT_READ, MAP_SHARED, fd, 0);
            if (ptr != MAP_FAILED) {
                NSData* data = [NSData dataWithBytesNoCopy:ptr length:size freeWhenDone:NO];
                result = [[PAK alloc] initWithData:data];
                result->_isMemoryMapped = YES;
            }
        }
    }
    close(fd);
    if (result) {
        NSLog(@"Loaded expansion file: %@", filename);
    } else {
        NSLog(@"Failed to load expansion file: %@ error: %s", filename, strerror(errno));
    }
    return result;
}

- (instancetype) initWithData:(NSData*)data
{
    self = [super init];
    if (self) {
        _data = data;
        _isMemoryMapped = NO;

        NSAssert(_data.length >= 16, @".pak file is too small");
        NSAssert(memcmp(_data.bytes, "AP_Pack!", 8) == 0, @"Bad .pak file signature");

        uint32_t totalSize = [self wordAtOffset:8];
        uint32_t dirOffset = [self wordAtOffset:12];

        NSAssert(data.length == totalSize, @".pak file is %lu bytes, expected %d", data.length, totalSize);
        NSAssert((dirOffset & 15) == 0, @".pak directory isn't 16-byte aligned");
        NSAssert(totalSize >= dirOffset, @".pak directory location is out of bounds");

        uint32_t dirSize = (totalSize - dirOffset) / 20;
        NSMutableDictionary* items = [NSMutableDictionary dictionaryWithCapacity:dirSize];
        for (uint32_t pos = dirOffset; pos < totalSize; pos += 20) {
            PAK_Item* item = [self blob:pos];
            items[item.name] = item;
        }
        _items = [NSDictionary dictionaryWithDictionary:items];
    }
    return self;
}

- (void) dealloc
{
    if (_isMemoryMapped) {
        int err = munmap((void*) [_data bytes], [_data length]);
        if (err) {
            NSLog(@"munmap() failed! Error: %s", strerror(errno));
        }
    }
}

- (PAK_Item*) blob:(uint32_t)blobOffset {
    NSString* name = [self string:blobOffset];
    uint32_t offset = [self wordAtOffset:(blobOffset + 8)];
    uint32_t fileSize = [self wordAtOffset:(blobOffset + 12)];
    uint32_t uncompressedSize = [self wordAtOffset:(blobOffset + 16)];
    char* base = (char*)[_data bytes];
    NSData* data = [NSData dataWithBytesNoCopy:(base + offset) length:fileSize freeWhenDone:NO];
    return [[PAK_Item alloc] initWithName:name length:uncompressedSize data:data];
}

- (NSString*) string:(uint32_t)strOffset {
    uint32_t offset = [self wordAtOffset:(strOffset)];
    uint32_t length = [self wordAtOffset:(strOffset + 4)];
    char* base = (char*)[_data bytes];
    NSData* data = [NSData dataWithBytesNoCopy:(base + offset) length:length freeWhenDone:NO];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (uint32_t) wordAtOffset:(uint32_t)offset {
    assert((offset & 3) == 0);
    const uint32_t* ptr = (const uint32_t*) _data.bytes;
    return ptr[offset / 4];
}

- (NSArray*) pakNames
{
	return _items.allKeys;
}

- (PAK_Item*) pakItem:(NSString*)name
{
    return [_items objectForKey:name];
}

@end

// ---------------------------------------------------------------------------------------

@implementation PAK_Search

static NSMutableArray* g_paks;

+ (void) initialize
{
    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        g_paks = [NSMutableArray array];
    }
}

+ (void) add:(id<PAK_Reader>)pak
{
    [g_paks addObject:pak];
    [[NSNotificationCenter defaultCenter] postNotificationName:PAK_SearchPathChangedNotification object:nil];
}

+ (void) remove:(id<PAK_Reader>)pak
{
    [g_paks removeObject:pak];
    [[NSNotificationCenter defaultCenter] postNotificationName:PAK_SearchPathChangedNotification object:nil];
}

+ (NSArray*) names
{
	NSMutableSet* set = [NSMutableSet setWithCapacity:100];
    for (id<PAK_Reader> pak in g_paks) {
    	[set addObjectsFromArray:pak.pakNames];
    }
    return set.allObjects;
}

+ (PAK_Item*) item:(NSString*)name
{
    for (id<PAK_Reader> pak in g_paks) {
    	PAK_Item* result = [pak pakItem:name];
    	if (result) {
    		return result;
    	}
    }
    return nil;
}

@end
