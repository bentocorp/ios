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
- (BOOL)hasCreditCard;

- (STPCard *)getCreditCard;
- (void)setCreditCard:(STPCard *)card;

- (NSString *)getErrorMessage:(id)errorInfo;

@end
