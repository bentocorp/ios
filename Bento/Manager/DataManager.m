//
//  DataManager.m
//  Bento App
//
//  Created by hanjinghe on 8/8/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "DataManager.h"

#ifdef DEV_MODE

@implementation NSURLRequest (IgnoreSSL)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host
{
    return YES;
}
@end

#endif

@interface DataManager ()

@property (nonatomic) NSDictionary *currentUserInfo;
@property (nonatomic) STPCard *creditCardInfo;
@property (nonatomic) PaymentMethod curPaymentMethod;

@end

@implementation DataManager

static DataManager *_shareDataManager;

+ (DataManager *)shareDataManager
{
    @synchronized(self) {
        
        if (_shareDataManager == nil)
            _shareDataManager = [[DataManager alloc] init];
    }
    
    return _shareDataManager;
}

+ (void)releaseDataManager
{
    if (_shareDataManager != nil)
        _shareDataManager = nil;
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

+ (BOOL)isValidMailAddress:(NSString *)strMailAddr
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:strMailAddr];
}

+ (BOOL)isValidPhoneNumber:(NSString *)strPhoneNumber
{
//    NSString *phoneRegex = @"^(\\+1) (\\([0-9]{3})\\) [0-9]{3} - [0-9]{4}$";
    NSString *phoneRegex = @"(\\([0-9]{3})\\) [0-9]{3} - [0-9]{4}$";
    NSPredicate *phoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", phoneRegex];

    NSMutableArray *characters = [[NSMutableArray alloc] initWithCapacity:[strPhoneNumber length]];
    for (int i = 0; i < [strPhoneNumber length]; i++)
    {
        NSString *ichar = [NSString stringWithFormat:@"%c", [strPhoneNumber characterAtIndex:i]];
        [characters addObject:ichar];
    }
    
    if ([characters[1] isEqualToString:@"1"]) {
        return NO;
    }
    
    BOOL isValid = [phoneTest evaluateWithObject:strPhoneNumber];
    return isValid;
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

- (void)setUserInfo:(NSDictionary *)userInfo paymentMethod:(PaymentMethod)paymentMethod
{
    self.currentUserInfo = userInfo;
    [self setPaymentMethod:paymentMethod];
}

- (void)setUserInfo:(NSDictionary *)userInfo
{
    self.currentUserInfo = userInfo;
    
    self.paymentMethod = Payment_None;
    
    if (self.currentUserInfo != nil)
    {
        NSDictionary *cardInfo = [self.currentUserInfo objectForKey:@"card"];
        if ([cardInfo isKindOfClass:[NSDictionary class]] && cardInfo != nil)
        {
            NSString *strCardNumber = [cardInfo objectForKey:@"last4"];
            NSString *strUserMail = [self.currentUserInfo objectForKey:@"email"];
            
            // Load Card Info
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            NSString *strSavedUserMail = [userDefaults objectForKey:@"user_email"];
            if ([strSavedUserMail isEqualToString:strUserMail])
            {
                if ([[userDefaults objectForKey:@"is_applepay"] boolValue])
                    self.paymentMethod = Payment_ApplePay;
                else
                    self.paymentMethod = Payment_Server;
            }
            else
            {
                if ([strCardNumber isEqualToString:@"0000"])
                    self.paymentMethod = Payment_ApplePay;
                else
                    self.paymentMethod = Payment_Server;
            }
        }
    }
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

- (STPCard *)getCreditCard
{
    return self.creditCardInfo;
}

- (void)setCreditCard:(STPCard *)creditCardInfo
{
    self.creditCardInfo = creditCardInfo;
    
    if (creditCardInfo == nil)
        self.paymentMethod = Payment_None;
    else
        self.paymentMethod = Payment_CreditCard;
}

- (PaymentMethod)getPaymentMethod
{
    return self.curPaymentMethod;
}

- (void)setPaymentMethod:(PaymentMethod)newPaymentMethod
{
    self.curPaymentMethod = newPaymentMethod;
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
