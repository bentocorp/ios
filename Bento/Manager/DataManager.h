//
//  DataManager.h
//  Bento App
//
//  Created by hanjinghe on 8/8/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DataManager : NSObject

+ (DataManager *)shareDataManager;
+ (void)releaseDataManager;

+ (UIColor *)getGradientColor1;
+ (UIColor *)getGradientColor2;

+ (BOOL)isValidMailAddress:(NSString *)strMailAddr;

+ (BOOL)isValidPhoneNumber:(NSString *)strPhoneNumber;

@end
