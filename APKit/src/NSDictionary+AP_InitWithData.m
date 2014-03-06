#import "NSDictionary+AP_InitWithData.h"

#import "AP_Bundle.h"

@implementation NSDictionary(AP_InitWithData)

- (instancetype) initWithPlistData:(NSData*)data
{
    NSString* s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary* d = [s propertyList];
    return [self initWithDictionary:d];
}

+ (instancetype) dictionaryWithPlistData:(NSData*)data
{
    NSString* s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary* d = [s propertyList];
    return [NSDictionary dictionaryWithDictionary:d];
}

@end
