//
//  DataManager.m
//  Bento App
//
//  Created by hanjinghe on 8/8/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "DataManager.h"

@implementation DataManager

static DataManager *_shareDataManager;

+ (DataManager *)shareDataManager
{
    @synchronized(self) {
        
        if(_shareDataManager == nil)
        {
            _shareDataManager = [[DataManager alloc] init];
        }
    }
    
    return _shareDataManager;
}

+ (void)releaseDataManager
{
    if(_shareDataManager != nil)
    {
        _shareDataManager = nil;
    }
}

- (id) init
{
	if ( (self = [super init]) )
	{
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
    NSString *phoneRegex = @"^(\\([0-9]{3})\\) [0-9]{3}-[0-9]{4}$";
    NSPredicate *phoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", phoneRegex];
    return [phoneTest evaluateWithObject:strPhoneNumber];
}

@end
