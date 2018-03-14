#pragma once

#import <Foundation/Foundation.h>

@class PFObject;
@class PFUser;

typedef void (^PFBooleanResultBlock)(BOOL succeeded, NSError *error);
typedef void (^PFIntegerResultBlock)(int number, NSError *error);
typedef void (^PFArrayResultBlock)(NSArray *objects, NSError *error);
typedef void (^PFObjectResultBlock)(PFObject *object, NSError *error);
typedef void (^PFSetResultBlock)(NSSet *channels, NSError *error);
typedef void (^PFUserResultBlock)(PFUser *user, NSError *error);
typedef void (^PFDataResultBlock)(NSData *data, NSError *error);
typedef void (^PFDataStreamResultBlock)(NSInputStream *stream, NSError *error);
typedef void (^PFStringResultBlock)(NSString *string, NSError *error);
typedef void (^PFIdResultBlock)(id object, NSError *error);
typedef void (^PFProgressBlock)(int percentDone);
