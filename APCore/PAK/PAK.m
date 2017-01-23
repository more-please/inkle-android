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

@interface PAK_WeakCache_Entry : NSObject
@property (nonatomic,strong) id key;
@property (nonatomic,weak) id value;
@end

@implementation PAK_WeakCache_Entry
@end

@interface PAK_WeakCache : NSObject
- (id) get:(id)key withLoader:(id(^)(void))block;
@end

@implementation PAK_WeakCache {
    NSMutableDictionary* _dict;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        _dict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id) get:(id)key withLoader:(id (^)(void))loader
{
    PAK_WeakCache_Entry* entry = [_dict objectForKey:key];
    id result = entry.value;
    if (!result) {
        result = loader();
        if (!result) {
            return nil;
        }
        entry = [[PAK_WeakCache_Entry alloc] init];
        entry.key = key;
        entry.value = result;
        [_dict setObject:entry forKey:key];
    }
    return result;
}

@end

// ---------------------------------------------------------------------------------------

@implementation PAK_Item {
    PAK* _parent;
    NSData* _originalData;
    __weak NSData* _uncompressedData;
}

- (instancetype) initWithParent:(PAK*)parent name:(NSString*)name length:(int)length data:(NSData*)data
{
	self = [super init];
	if (self) {
        _parent = parent;
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

#ifdef WINDOWS

#include <shlobj.h>
#include <shlwapi.h>

static BOOL cdToDataDir() {
    uint16_t* wpath;
    HRESULT err = SHGetKnownFolderPath(
        &FOLDERID_LocalAppData,
        KF_FLAG_CREATE | KF_FLAG_INIT,
        NULL,
        &wpath);
    if (err) {
        return NO;
    }
    if (!SetCurrentDirectoryW(wpath)) {
        return NO;
    }
    return YES;
}

static BOOL cdToExeDir() {
    uint16_t path[512];
    if (!GetModuleFileNameW(NULL, path, 512)) {
        return NO;
    }
    PathRemoveFileSpecW(path);
    if (!SetCurrentDirectoryW(path)) {
        return NO;
    }
    return YES;
}

#endif

// ---------------------------------------------------------------------------------------

@implementation PAK {
    BOOL _isMemoryMapped;
    NSDictionary* _names; // Map of name -> pos
    PAK_WeakCache* _cache; // Cache of name -> PAK_Item
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
#ifdef WINDOWS
    cdToExeDir();
#endif
    PAK* result = [self pakWithMemoryMappedFile_internal:filename];
#ifdef WINDOWS
    cdToDataDir();
#endif
    return result;
}

+ (PAK*) pakWithMemoryMappedFile_internal:(NSString*)filename
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:filename]) {
        NSLog(@"Missing expansion file: %@", filename);
        return nil;
    }
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
        NSMutableDictionary* names = [NSMutableDictionary dictionaryWithCapacity:dirSize];
        for (uint32_t pos = dirOffset; pos < totalSize; pos += 20) {
            NSString* name = [self string:pos];
            names[name] = @(pos);
        }
        _names = [NSDictionary dictionaryWithDictionary:names];
        _cache = [[PAK_WeakCache alloc] init];
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
    return [[PAK_Item alloc] initWithParent:self name:name length:uncompressedSize data:data];
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
	return _names.allKeys;
}

- (PAK_Item*) pakItem:(NSString*)name
{
    return [_cache get:name withLoader:^{
        NSNumber* pos = _names[name];
        return pos ? [self blob:pos.intValue] : nil;
    }];
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
