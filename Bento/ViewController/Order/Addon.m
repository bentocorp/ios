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
        self.name = dictionary[@"name"];
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
    
    [[AddonList sharedInstance] saveList];
    
    NSLog(@"ID: %ld, Quantity - %ld, Unit Price - %f", (long)self.itemId, (long)self.qty, self.unitPrice);
}

- (void)removeOneCount {
    if (self.qty > 0) {
        self.qty -= 1;
        
        NSLog(@"ID: %ld, Quantity - %ld, Unit Price - %f", (long)self.itemId, (long)self.qty, self.unitPrice);
    }
    
    [self checkIfLastCount];
    
    // save results
    [[AddonList sharedInstance] saveList];
}

// if none, remove addon from list
- (void)checkIfLastCount {
    if (self.qty <= 0) {
        for (int i = 0; i < [AddonList sharedInstance].addonList.count; i++) {
            
            Addon *addon = [AddonList sharedInstance].addonList[i];
            
            if (self.itemId == addon.itemId) {
                [[AddonList sharedInstance] removeFromList:i];
            }
        }
    }
}

- (BOOL)checkIfItemIsSoldOut:(NSMutableArray *)itemIds
{
    for (int i = 0; i < itemIds.count; i++) {
        
        NSInteger itemId = [itemIds[i] integerValue];
        
        if  (self.itemId == itemId) {
            return YES;
        }
    }
    
    return NO;
}

@end
