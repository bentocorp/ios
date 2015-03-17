//
//  DataManager.h
//  Bento App
//
//  Created by hanjinghe on 8/8/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "Stripe.h"

#ifndef DEV_MODE
#define SERVER_URL @"https://api.bentonow.com"
#else
#define SERVER_URL @"https://dev.api.bentonow.com"
#endif

#define GOOGLE_API_KEY @"AIzaSyCv7nwsR9ppbEWPwCKnZ9f6nf3UTli-ZLk"

typedef enum : NSUInteger {
    ERROR_NONE,
    ERROR_USERNAME,
    ERROR_EMAIL,
    ERROR_NO_EMAIL,
    ERROR_PHONENUMBER,
    ERROR_PASSWORD,
    ERROR_UNKNOWN,
} ERROR_TYPE;

typedef enum : NSUInteger {
    Payment_None,
    Payment_Server,
    Payment_ApplePay,
    Payment_CreditCard,
} PaymentMethod;

#ifdef DEV_MODE

@interface NSURLRequest (IgnoreSSL)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
@end

#endif

@interface DataManager : NSObject

+ (DataManager *)shareDataManager;
+ (void)releaseDataManager;

+ (UIColor *)getGradientColor1;
+ (UIColor *)getGradientColor2;

+ (BOOL)isValidMailAddress:(NSString *)strMailAddr;
+ (BOOL)isValidPhoneNumber:(NSString *)strPhoneNumber;

+ (NSString *)getAddressString:(NSDictionary *)googleResponse;

- (NSDictionary *)getUserInfo;
- (void)setUserInfo:(NSDictionary *)userInfo;

- (NSString *)getAPIToken;

- (BOOL)isAdminUser;

- (STPCard *)getCreditCard;
- (void)setCreditCard:(STPCard *)card;

- (PaymentMethod)getPaymentMethod;
- (void)setPaymentMethod:(PaymentMethod)newPaymentMethod;

- (NSString *)getErrorMessage:(id)errorInfo;

@end
