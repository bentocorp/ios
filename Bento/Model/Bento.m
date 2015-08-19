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
    if (self = [super init])
    {
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
    
    NSDictionary *dishInfo = [[BentoShop sharedInstance] getMainDish:self.indexMainDish];
    if (dishInfo == nil) {
        return @"";
    }
    
    return [dishInfo objectForKey:@"name"];
}

- (NSInteger)getMainDish
{
    return self.indexMainDish;
}

- (void)setMainDish:(NSInteger)indexMainDish
{
    self.indexMainDish = indexMainDish;
    [[BentoShop sharedInstance] saveBentoArray];
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

@end
