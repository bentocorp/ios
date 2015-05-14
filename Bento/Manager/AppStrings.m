//
//  AppStrings.m
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "AppStrings.h"

#import "WebManager.h"
#import "DataManager.h"

@implementation AppStrings

static AppStrings *_shareInstance;

+ (AppStrings *)sharedInstance
{
    @synchronized(self) {
        
        if (_shareInstance == nil)
        {
            _shareInstance = [[AppStrings alloc] init];
        }
    }
    
    return _shareInstance;
}

+ (void)releaseInstance
{
    if (_shareInstance != nil)
    {
        _shareInstance = nil;
    }
}

- (id) init
{
    if ( (self = [super init]) )
    {
        self.appStrings = nil;
    }
    
    return self;
}

- (void)getAppStrings
{
    NSString *strRequest = [NSString stringWithFormat:@"%@/ioscopy", SERVER_URL];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:strRequest]];
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    if (data == nil)
        return;
    
    NSInteger statusCode = 0;
    if ([response isKindOfClass:[NSHTTPURLResponse class]])
        statusCode = [(NSHTTPURLResponse *)response statusCode];
    
    if (error != nil || statusCode != 200)
        return;
    
    NSError *parseError = nil;
    NSArray *aryRet = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
    if (aryRet == nil)
        return;
    
    self.appStrings = [aryRet copy];
    
    NSLog(@"appStrings - %@", aryRet);
}

- (NSURL *)getURL:(NSString *)strKey
{
    if (self.appStrings == nil)
        return nil;
    
    for (NSDictionary *info in self.appStrings)
    {
        NSString *key = [info objectForKey:@"key"];
        NSString *type = [info objectForKey:@"type"];
        if ([key isEqualToString:strKey] && [type isEqualToString:@"url"])
        {
            NSString *value = [info objectForKey:@"value"];
            return [NSURL URLWithString:value];
        }
    }
    
    return nil;
}

- (NSString *)getString:(NSString *)strKey
{
    if (self.appStrings == nil) {
        return nil;
    }
    
    for (NSDictionary *info in self.appStrings)
    {
        NSString *key = [info objectForKey:@"key"];
        NSString *type = [info objectForKey:@"type"];
        if ([key isEqualToString:strKey] && [type isEqualToString:@"text"])
        {
            return [info objectForKey:@"value"]; // return string value
        }
    }
    
    return nil;
}

- (NSInteger)getInteger:(NSString *)strKey
{
    if (self.appStrings == nil)
        return 0;
    
    for (NSDictionary *info in self.appStrings)
    {
        NSString *key = [info objectForKey:@"key"];
        NSString *type = [info objectForKey:@"type"];
        if ([key isEqualToString:strKey] && [type isEqualToString:@"number"])
        {
            NSInteger value = [[info objectForKey:@"value"] integerValue];
            return value;
        }
    }
    
    return 0;
}

- (NSString *)getContactMail
{
    if (self.appStrings == nil)
        return nil;
    
    for (NSDictionary *info in self.appStrings)
    {
        NSString *key = [info objectForKey:@"key"];
        if ([key isEqualToString:@"contact-email"])
        {
            NSString *strValue = [info objectForKey:@"value"];
            return strValue;
        }
    }
    
    return 0;
}

@end
