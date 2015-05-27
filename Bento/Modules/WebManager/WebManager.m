//
//  WebManager.m
//  BrighterLink
//
//  Created by mobile master on 11/5/14.
//  Copyright (c) 2014 Brightergy. All rights reserved.
//

// Read the following link to know in more detail
// https://github.com/AFNetworking/AFNetworking

#import "WebManager.h"

@implementation WebManager

-(id)init
{
    if (self = [super init])
    {
        m_engine = [[MKNetworkEngine alloc] init];
    }
    return self;
}

-(void)dealloc
{
    [m_engine cancelAllOperations];
}

-(void)AsyncProcess:(NSString *)strAPIName method:(Method)method parameters:(NSDictionary*)params success:(SuccessBlock)success failure:(ErrorBlock)failure isJSON:(BOOL)isJSON
{
    m_apiURL = strAPIName;
    
    NSString* strMethod = @"GET";
    switch (method) {
        case GET:
            strMethod = @"GET";
            break;
        case POST:
            strMethod = @"POST";
            break;
        case PUT:
            strMethod = @"PUT";
            break;
        case PATCH:
            strMethod = @"PATCH";
            break;
        case DELETE:
            strMethod = @"DELETE";
            break;
        default:
            break;
    }
    
    if (params && [params isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"%@", [params jsonEncodedKeyValueString]);
    }
    
    NSArray *aryParams = nil;
    if ([params isKindOfClass:[NSArray class]])
    {
        aryParams = (NSArray *)params;
        params = nil;
    }
    
    MKNetworkOperation* op = [[MKNetworkOperation alloc] initWithURLString:m_apiURL params:params httpMethod:strMethod];
    if (isJSON)
        [op setPostDataEncoding:MKNKPostDataEncodingTypeJSON];

    if (aryParams != nil)
    {
        [op setCustomPostDataEncodingHandler:^NSString *(NSDictionary *postDataDict) {
            
            NSDictionary *dicParams = nil;
            
            if (aryParams.count > 0)dicParams = [aryParams objectAtIndex:0];
            
            NSString *postString = [NSString stringWithFormat:@"\[%@]", [dicParams jsonEncodedKeyValueString]];
            
            return postString;
            
        } forType:@"application/json"];
    }
    
    [op addCompletionHandler:success errorHandler:failure];
    
    [m_engine enqueueOperation:op];
}

@end
