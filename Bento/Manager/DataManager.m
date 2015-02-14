//
//  DataManager.m
//  Bento App
//
//  Created by hanjinghe on 8/8/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "DataManager.h"

@interface DataManager ()

@property (nonatomic, retain) NSDictionary *currentUserInfo;

@property (nonatomic, retain) STPCard *creditCardInfo;

@end

@implementation DataManager

static DataManager *_shareDataManager;

+ (DataManager *)shareDataManager
{
    @synchronized(self) {
        
        if (_shareDataManager == nil)
        {
            _shareDataManager = [[DataManager alloc] init];
        }
    }
    
    return _shareDataManager;
}

+ (void)releaseDataManager
{
    if (_shareDataManager != nil)
    {
        _shareDataManager = nil;
    }
}

- (id) init
{
	if ( (self = [super init]) )
	{
        self.currentUserInfo = nil;
        self.creditCardInfo = nil;
	}
	
	return self;
}

+ (UIColor *)getGradientColor1
{
    return [UIColor colorWithRed:156.f/255.f green:211.f/255.f blue:101.f/255.f alpha:0.8f];
}

+ (UIColor *)getGradientColor2
{
    return [UIColor colorWithRed:125.f/255.f green:170.f/255.f blue:82.f/255.f alpha:0.8f];
}

+ (BOOL)isValidMailAddress:(NSString *)strMailAddr
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:strMailAddr];
}

+ (BOOL)isValidPhoneNumber:(NSString *)strPhoneNumber
{
    NSString *phoneRegex = @"^(\\([0-9]{3})\\) [0-9]{3} - [0-9]{4}$";
    NSPredicate *phoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", phoneRegex];
    return [phoneTest evaluateWithObject:strPhoneNumber];
//    NSMutableCharacterSet *characterSet = [NSMutableCharacterSet decimalDigitCharacterSet];
//    [characterSet addCharactersInString:@"'-*+#,;. "];
//    return ([strPhoneNumber rangeOfCharacterFromSet:[characterSet invertedSet]].location == NSNotFound);
}

+ (NSString *)getAddressString:(NSDictionary *)googleResponse
{
    if (googleResponse == nil)
        return nil;
    
    NSString *strAddress = [googleResponse objectForKey:@"formatted_address"];
    if (strAddress != nil && strAddress.length > 0)
        return strAddress;
    
    return nil;
}

- (NSDictionary *)getUserInfo
{
    return self.currentUserInfo;
}

- (void)setUserInfo:(NSDictionary *)userInfo
{
    self.currentUserInfo = userInfo;
}

- (NSString *)getAPIToken
{
    if (self.currentUserInfo == nil)
        return nil;
    
    return [self.currentUserInfo objectForKey:@"api_token"];
}

- (BOOL)isAdminUser
{
    if (self.currentUserInfo == nil)
        return NO;
    
    return [[self.currentUserInfo objectForKey:@"is_admin"] boolValue];
}

- (BOOL)hasCreditCard
{
    if (self.currentUserInfo == nil)
        return NO;
    
    id object = [self.currentUserInfo objectForKey:@"card"];
    if (object == nil)
        return NO;
    
    if (object == [NSNull null])
        return NO;
    
    return YES;
}

- (STPCard *)getCreditCard
{
    return self.creditCardInfo;
}

- (void)setCreditCard:(STPCard *)creditCardInfo
{
    self.creditCardInfo = creditCardInfo;
}

- (NSString *)getErrorMessage:(id)errorInfo
{
    NSString *strMessage = nil;
    if([errorInfo isKindOfClass:[NSDictionary class]])
    {
        if ([errorInfo objectForKey:@"error"])
            strMessage = [errorInfo objectForKey:@"error"];
        else
            strMessage = [errorInfo objectForKey:@"Error"];
    }
    else if([errorInfo isKindOfClass:[NSArray class]])
    {
        NSArray *errorInfoArrary = (NSArray *)errorInfo;
        if(errorInfoArrary.count > 0)
            strMessage = [NSString stringWithFormat:@"%@", [errorInfoArrary objectAtIndex:0]];
    }
    
    return strMessage;
}

@end
