#import "NSDictionary+AP_InitWithData.h"

#import "AP_Bundle.h"

@implementation NSDictionary(AP_InitWithData)

- (instancetype) initWithData:(NSData*)data
{
    NSString* s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary* d = [s propertyList];
    return [self initWithDictionary:d];
}

+ (instancetype) dictionaryWithData:(NSData*)data
{
    NSString* s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary* d = [s propertyList];
    return [NSDictionary dictionaryWithDictionary:d];
}

@end
