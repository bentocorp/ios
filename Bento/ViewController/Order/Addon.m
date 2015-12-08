//
//  Addon.m
//  Bento
//
//  Created by Joseph Lau on 11/17/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import "Addon.h"
#import "AddonList.h"
#import "BentoShop.h"

@implementation Addon

- (id)initWithDictionary:(NSDictionary *)dictionary {
    
    if (self = [super init]) {

        self.itemId = [dictionary[@"itemId"] integerValue];
        self.qty = 0;
        
        if (dictionary[@"price"] == nil || [dictionary[@"price"] isEqual:[NSNull null]] || [dictionary[@"price"] isEqualToString:@""]) {
            self.unitPrice = [[[BentoShop sharedInstance] getUnitPrice] floatValue]; // default unit price if not set
        }
        else {
            self.unitPrice = [dictionary[@"price"] floatValue];
        }
    }
    
    return self;
}

- (void)addOneCount {
    self.qty += 1;
    
    NSLog(@"ID: %ld, Quantity - %ld, Unit Price - %f", self.itemId, self.qty, self.unitPrice);
    
    // save results
    [[AddonList sharedInstance] saveList];
}

- (void)removeOneCount {
    if (self.qty > 0) {
        self.qty -= 1;
        
        NSLog(@"ID: %ld, Quantity - %ld, Unit Price - %f", self.itemId, self.qty, self.unitPrice);
    }
    
    // save results
    [[AddonList sharedInstance] saveList];
}

@end
