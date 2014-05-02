#import "PAK.h"

#import <fcntl.h>
#import <sys/mman.h>

// ---------------------------------------------------------------------------------------

@implementation PAK_Item

- (instancetype) initWithPath:(NSString*)path isAsset:(BOOL)isAsset offset:(int)offset length:(int)length data:(NSData*)data
{
	self = [super init];
	if (self) {
		_path = path;
		_isAsset = isAsset;
		_offset = offset;
		_length = length;
		_data = data;
	}
	return self;
}

@end

// ---------------------------------------------------------------------------------------

@implementation PAK {
    BOOL _isMemoryMapped;
    NSDictionary* _items;
}

+ (PAK*) pakWithAsset:(NSString*)name data:(NSData*)data
{
    PAK* result = [[PAK alloc] initWithPath:name data:data];
    result->_isAsset = YES;
    return result;
}

+ (PAK*) pakWithMemoryMappedFile:(NSString*)filename
{
    PAK* result = nil;
    int fd = open([filename UTF8String], O_RDONLY);
    if (fd > 0) {
        long size = lseek(fd, 0, SEEK_END);
        if (size > 0) {
            uint8_t* ptr = mmap(0, size, PROT_READ, MAP_PRIVATE, fd, 0);
            if (ptr != MAP_FAILED) {
                NSData* data = [NSData dataWithBytesNoCopy:ptr length:size freeWhenDone:NO];
                result = [[PAK alloc] initWithPath:filename data:data];
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

- (instancetype) initWithPath:(NSString*)path data:(NSData*)data
{
    self = [super init];
    if (self) {
        _path = path;
        _data = data;
        _isMemoryMapped = NO;

        NSAssert(_data.length >= 16, @".pak file is too small");
        NSAssert(memcmp(_data.bytes, "AP_Pack!", 8) == 0, @"Bad .pak file signature");

        uint32_t totalSize = [self wordAtOffset:8];
        uint32_t dirOffset = [self wordAtOffset:12];

        NSAssert(data.length == totalSize, @".pak file is %d bytes, expected %d", data.length, totalSize);
        NSAssert((totalSize & 15) == 0, @".pak file size (%d) isn't 16-byte aligned", totalSize);
        NSAssert((dirOffset & 15) == 0, @".pak directory isn't 16-byte aligned");
        NSAssert(totalSize >= dirOffset, @".pak directory location is out of bounds");

        uint32_t dirSize = (totalSize - dirOffset) / 16;
        NSMutableDictionary* items = [NSMutableDictionary dictionaryWithCapacity:dirSize];
        for (uint32_t pos = dirOffset; pos < totalSize; pos += 16) {
            NSString* name = [[NSString alloc] initWithData:[self blob:pos].data encoding:NSUTF8StringEncoding];
            PAK_Item* item = [self blob:(pos + 8)];
            items[name] = item;
        }
        _items = [NSDictionary dictionaryWithDictionary:items];
    }
    return self;
}

- (void) dealloc
{
    if (_isMemoryMapped) {
        int result = munmap((void*) [_data bytes], [_data length]);
        NSAssert(result == 0, @"munmap() failed! Error: %s", strerror(errno));
    }
}

- (PAK_Item*) blob:(uint32_t)blobOffset {
    uint32_t offset = [self wordAtOffset:(blobOffset)];
    uint32_t length = [self wordAtOffset:(blobOffset + 4)];
	char* base = (char*)[_data bytes];
	NSData* data = [NSData dataWithBytesNoCopy:(base + offset) length:length freeWhenDone:NO];
    return [[PAK_Item alloc] initWithPath:_path isAsset:_isAsset offset:offset length:length data:data];
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
