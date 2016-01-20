//
//  Bento.m
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "Bento.h"
#import "BentoShop.h"

@interface Bento()

@end

@implementation Bento

- (id)init
{
    if (self = [super init]) {
        self.indexMainDish = 0;
        self.indexSideDish1 = 0;
        self.indexSideDish2 = 0;
        self.indexSideDish3 = 0;
        self.indexSideDish4 = 0;
    }
    
    return self;
}

- (NSString *)getBentoName
{
    if (self.indexMainDish == 0)
        return @"";
    
    NSDictionary *dishInfo;
    
    // is on demand
    if (self.orderAheadMenu == nil) {
        dishInfo = [[BentoShop sharedInstance] getMainDish:self.indexMainDish];
    }
    else {
        dishInfo = [self.orderAheadMenu getMainDish:self.indexMainDish];
    }
    
    if (dishInfo == nil) {
        return @"";
    }
    
    return [dishInfo objectForKey:@"name"];
}

- (float)getUnitPrice {
    if (self.indexMainDish == 0)
        return 0;
    
    NSDictionary *dishInfo;
    
    // is on demand
    if (self.orderAheadMenu == nil) {
        dishInfo = [[BentoShop sharedInstance] getMainDish:self.indexMainDish];
    }
    else {
        dishInfo = [self.orderAheadMenu getMainDish:self.indexMainDish];
    }
    
    if (dishInfo == nil) {
        return 0;
    }
    
    if ([dishInfo[@"price"] isEqual:[NSNull null]] || dishInfo[@"price"] == nil || dishInfo[@"price"] == 0 || [dishInfo[@"price"] isEqualToString:@""]) {
        return [[[BentoShop sharedInstance] getUnitPrice] floatValue];
    }
    
    return [dishInfo[@"price"] floatValue];
}

- (NSInteger)getMainDish
{
    return self.indexMainDish;
}

- (NSInteger)getSideDish1
{
    return self.indexSideDish1;
}

- (NSInteger)getSideDish2
{
    return self.indexSideDish2;
}

- (NSInteger)getSideDish3
{
    return self.indexSideDish3;
}

- (NSInteger)getSideDish4
{
    return self.indexSideDish4;
}

- (void)setMainDish:(NSInteger)indexMainDish
{
    self.indexMainDish = indexMainDish;
    [[BentoShop sharedInstance] saveBentoArray];
}

- (void)setSideDish1:(NSInteger)indexSideDish
{
    self.indexSideDish1 = indexSideDish;
    [[BentoShop sharedInstance] saveBentoArray];
}

- (void)setSideDish2:(NSInteger)indexSideDish
{
    self.indexSideDish2 = indexSideDish;
    [[BentoShop sharedInstance] saveBentoArray];
}

- (void)setSideDish3:(NSInteger)indexSideDish
{
    self.indexSideDish3 = indexSideDish;
    [[BentoShop sharedInstance] saveBentoArray];
}

- (void)setSideDish4:(NSInteger)indexSideDish
{
    self.indexSideDish4 = indexSideDish;
    [[BentoShop sharedInstance] saveBentoArray];
}

- (BOOL)isEmpty
{
    return (self.indexMainDish == 0 &&
            self.indexSideDish1 == 0 &&
            self.indexSideDish2 == 0 &&
            self.indexSideDish3 == 0 &&
            self.indexSideDish4 == 0);
}

- (BOOL)isCompleted
{
    return (self.indexMainDish != 0 &&
            self.indexSideDish1 != 0 &&
            self.indexSideDish2 != 0 &&
            self.indexSideDish3 != 0 &&
            self.indexSideDish4 != 0);
}

// for on demand
- (void)completeBento:(NSString *)whatNeedsThis
{
    if (self.indexMainDish == 0)
    {
        NSArray *aryMainDishes = [[BentoShop sharedInstance] getMainDishes:whatNeedsThis];
        
        for (NSDictionary *dishInfo in aryMainDishes)
        {
            NSInteger dishIndex = [[dishInfo objectForKey:@"itemId"] integerValue];
            if ([[BentoShop sharedInstance] isDishSoldOut:dishIndex]) {
                continue;
            }
            
            if (![[BentoShop sharedInstance] canAddDish:dishIndex]) {
                continue;
            }
            
            self.indexMainDish = dishIndex;
            break;
        }
    }

    if (self.indexSideDish1 == 0)
    {
        NSArray *arySideDishes = [[BentoShop sharedInstance] getSideDishes:whatNeedsThis];
        for (NSDictionary *dishInfo in arySideDishes)
        {
            NSInteger dishIndex = [[dishInfo objectForKey:@"itemId"] integerValue];
            if ([[BentoShop sharedInstance] isDishSoldOut:dishIndex])
                continue;
            
            if (![[BentoShop sharedInstance] canAddDish:dishIndex])
                continue;
            
            if (![self canAddSideDish:dishIndex])
                continue;
            
            self.indexSideDish1 = dishIndex;
            break;
        }
    }
    
    if (self.indexSideDish2 == 0)
    {
        NSArray *arySideDishes = [[BentoShop sharedInstance] getSideDishes:whatNeedsThis];
        for (NSDictionary *dishInfo in arySideDishes)
        {
            NSInteger dishIndex = [[dishInfo objectForKey:@"itemId"] integerValue];
            if ([[BentoShop sharedInstance] isDishSoldOut:dishIndex])
                continue;
            
            if (![[BentoShop sharedInstance] canAddDish:dishIndex])
                continue;
            
            if (![self canAddSideDish:dishIndex])
                continue;

            self.indexSideDish2 = dishIndex;
            break;
        }
    }
    
    if (self.indexSideDish3 == 0)
    {
        NSArray *arySideDishes = [[BentoShop sharedInstance] getSideDishes:whatNeedsThis];
        for (NSDictionary *dishInfo in arySideDishes)
        {
            NSInteger dishIndex = [[dishInfo objectForKey:@"itemId"] integerValue];
            if ([[BentoShop sharedInstance] isDishSoldOut:dishIndex])
                continue;
            
            if (![[BentoShop sharedInstance] canAddDish:dishIndex])
                continue;
            
            if (![self canAddSideDish:dishIndex])
                continue;
            
            self.indexSideDish3 = dishIndex;
            break;
        }
    }
    
    if (self.indexSideDish4 == 0)
    {
        NSArray *arySideDishes = [[BentoShop sharedInstance] getSideDishes:whatNeedsThis];
        for (NSDictionary *dishInfo in arySideDishes)
        {
            NSInteger dishIndex = [[dishInfo objectForKey:@"itemId"] integerValue];
            if ([[BentoShop sharedInstance] isDishSoldOut:dishIndex])
                continue;
            
            if (![[BentoShop sharedInstance] canAddDish:dishIndex])
                continue;
            
            if (![self canAddSideDish:dishIndex])
                continue;
            
            self.indexSideDish4 = dishIndex;
            break;
        }
    }

    [[BentoShop sharedInstance] saveBentoArray];
}

// completeBento, but order ahead version
- (void)completeBentoWithOrderAheadMenu
{
    if (self.indexMainDish == 0)
    {
        for (NSDictionary *dishInfo in self.orderAheadMenu.mainDishes)
        {
            NSInteger dishIndex = [[dishInfo objectForKey:@"itemId"] integerValue];
            if ([self.orderAheadMenu isDishSoldOut:dishIndex]) {
                continue;
            }
            
            if (![self.orderAheadMenu canAddDish:dishIndex]) {
                continue;
            }
            
            self.indexMainDish = dishIndex;
            break;
        }
    }
    
    if (self.indexSideDish1 == 0)
    {
        for (NSDictionary *dishInfo in self.orderAheadMenu.sideDishes)
        {
            NSInteger dishIndex = [[dishInfo objectForKey:@"itemId"] integerValue];
            if ([self.orderAheadMenu isDishSoldOut:dishIndex])
                continue;
            
            if (![self.orderAheadMenu canAddDish:dishIndex])
                continue;
            
            if (![self canAddSideDish:dishIndex])
                continue;
            
            self.indexSideDish1 = dishIndex;
            break;
        }
    }
    
    if (self.indexSideDish2 == 0)
    {
        for (NSDictionary *dishInfo in self.orderAheadMenu.sideDishes)
        {
            NSInteger dishIndex = [[dishInfo objectForKey:@"itemId"] integerValue];
            if ([self.orderAheadMenu isDishSoldOut:dishIndex])
                continue;
            
            if (![self.orderAheadMenu canAddDish:dishIndex])
                continue;
            
            if (![self canAddSideDish:dishIndex])
                continue;
            
            self.indexSideDish2 = dishIndex;
            break;
        }
    }
    
    if (self.indexSideDish3 == 0)
    {
        for (NSDictionary *dishInfo in self.orderAheadMenu.sideDishes)
        {
            NSInteger dishIndex = [[dishInfo objectForKey:@"itemId"] integerValue];
            if ([self.orderAheadMenu isDishSoldOut:dishIndex])
                continue;
            
            if (![self.orderAheadMenu canAddDish:dishIndex])
                continue;
            
            if (![self canAddSideDish:dishIndex])
                continue;
            
            self.indexSideDish3 = dishIndex;
            break;
        }
    }
    
    if (self.indexSideDish4 == 0)
    {
        for (NSDictionary *dishInfo in self.orderAheadMenu.sideDishes)
        {
            NSInteger dishIndex = [[dishInfo objectForKey:@"itemId"] integerValue];
            if ([self.orderAheadMenu isDishSoldOut:dishIndex])
                continue;
            
            if (![self.orderAheadMenu canAddDish:dishIndex])
                continue;
            
            if (![self canAddSideDish:dishIndex])
                continue;
            
            self.indexSideDish4 = dishIndex;
            break;
        }
    }
    
    [[BentoShop sharedInstance] saveBentoArray];
}

- (BOOL)canAddSideDish:(NSInteger)sideDishID
{   
    NSDictionary *dishInfo = [[BentoShop sharedInstance] getSideDish:sideDishID];
    if (dishInfo == nil) {
        return NO;
    }
    
    id object = [dishInfo objectForKey:@"max_per_order"];
    if (object == [NSNull null]) {
        return YES;
    }
    
    NSInteger maxPerOrder = [object integerValue];
    if (self.indexSideDish1 == sideDishID) {
        maxPerOrder --;
    }

    if (self.indexSideDish2 == sideDishID) {
        maxPerOrder --;
    }
    
    if (self.indexSideDish3 == sideDishID) {
        maxPerOrder --;
    }
    
    if (self.indexSideDish4 == sideDishID) {
        maxPerOrder --;
    }
    
    if (maxPerOrder <= 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)checkIfItemIsSoldOut:(NSMutableArray *)itemIds
{
    for (int i = 0; i < itemIds.count; i++) {
        
        NSInteger itemId = [itemIds[i] integerValue];
        
        if  (self.indexMainDish == itemId ||
             self.indexSideDish1 == itemId ||
             self.indexSideDish2 == itemId ||
             self.indexSideDish3 == itemId ||
             self.indexSideDish4 == itemId) {
            
            return YES; // sold-out item exists in bento
        }
    }
    
    return NO; // no sold-out item exists in bento
}

@end
