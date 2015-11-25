//
//  AddonList.m
//  Bento
//
//  Created by Joseph Lau on 11/17/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import "AddonList.h"
#import "Addon.h"
#import "NSUserDefaults+RMSaveCustomObject.h"

@implementation AddonList

- (id)init
{
    if (self = [super init]) {
        self.addonList = [[NSMutableArray alloc] init];
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

- (void)saveList {
    [[NSUserDefaults standardUserDefaults] rm_setCustomObject:self.addonList forKey:@"addonList"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)emptyList {
    if (self.addonList != nil && self.addonList.count != 0) {
        [self.addonList removeAllObjects];
        
        [[NSUserDefaults standardUserDefaults] rm_setCustomObject:self.addonList forKey:@"addonList"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (NSInteger)getTotalCount {
    
    NSInteger total = 0;
    
    for (int i = 0; i < self.addonList.count; i++) {
        
        Addon *addon = self.addonList[i];
        
        total += addon.qty;
    }
    
    return total;
}

@end
