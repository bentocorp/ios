//
//  WebManager.h
//  BrighterLink
//
//  Created by mobile master on 11/5/14.
//  Copyright (c) 2014 Brightergy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MKNetworkKit.h"

typedef enum : NSUInteger {
    GET = 0,
    POST,
    PUT,
    PATCH,
    DELETE
} Method;

@interface WebManager : NSObject
{
    MKNetworkEngine* m_engine;
    NSString* m_apiURL;
}

typedef void (^SuccessBlock)(MKNetworkOperation* networkOperation);
typedef void (^ErrorBlock)(MKNetworkOperation *errorOp, NSError* error);

@property (nonatomic) BOOL ProcessError;

- (void)AsyncProcess:(NSString *)strAPIName method:(Method)method parameters:(NSDictionary*)params success:(SuccessBlock)success failure:(ErrorBlock)failure isJSON:(BOOL)isJSON;

@end
