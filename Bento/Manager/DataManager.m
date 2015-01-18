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

@end
