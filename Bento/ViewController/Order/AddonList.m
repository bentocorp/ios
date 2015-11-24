//
//  AddonList.m
//  Bento
//
//  Created by Joseph Lau on 11/17/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import "AddonList.h"

@implementation AddonList

- (id)init
{
    if (self = [super init]) {
        
        self.addonsArray = [[NSMutableArray alloc] init];
    }
    
    return self;
}

+ (AddonList *)sharedInstance {
    
    // 1
    static AddonList *_sharedInstance = nil;
    
    // 2
    static dispatch_once_t oncePredicate;
    
    // 3
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[AddonList alloc] init];
    });
    return _sharedInstance;
}

@end
