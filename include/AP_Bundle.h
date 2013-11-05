#import <Foundation/Foundation.h>

#import "AP_PakReader.h"

// Wrapped for NSBundle. Also allows resource to be loaded from external .pak files.
// We use this on Android to manage extension files.
@interface AP_Bundle : NSObject

// Looks for the given resource in the .pak file(s), if any, then the main bundle.
+ (NSData*) dataForResource:(NSString *)name ofType:(NSString *)ext;

// Add the given .pak file to the end of the resource search path.
+ (void) addPak:(AP_PakReader*)pak;

@end
