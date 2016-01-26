//
//  OrderAheadMenu.m
//  Bento
//
//  Created by Joseph Lau on 1/19/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import "OrderAheadMenu.h"
#import "BentoShop.h"
#import "AddonList.h"

@implementation OrderAheadMenu

- (id)initWithDictionary:(NSDictionary *)menu {
    
    if (self = [super init]) {

        NSString *mealType = menu[@"Menu"][@"meal_name"];
        
        NSString *formattedDate = [[BentoShop sharedInstance] setDateFormat:menu[@"Menu"][@"for_date"]];
        
        self.name = [NSString stringWithFormat:@"%@, %@", formattedDate, [NSString stringWithFormat:@"%@%@",[[mealType substringToIndex:1] uppercaseString], [mealType substringFromIndex:1]]];
        
        self.allMenuItems = menu[@"MenuItems"];
        [self getMainDishes:menu];
        [self getSideDishes:menu];
        [self getAddons:menu];
        [self setUpTimes:menu[@"Times"]];
        
        self.orderType = @"2";
        self.mealType = menu[@"Menu"][@"meal_type"];
        self.kitchen = [[BentoShop sharedInstance] getKitchen];
        self.zone = [[BentoShop sharedInstance] getOAZone];
        self.forDate = menu[@"Menu"][@"for_date"];
        self.menuId = menu[@"Menu"][@"menu_id"];
        
        self.rawTimeRangesArray = menu[@"Times"];
    }
    
    return self;
}

- (void)getMainDishes:(NSDictionary *)menu {
    NSMutableArray *arrayDishes = [[NSMutableArray alloc] init];
    for (NSDictionary *dishInfo in self.allMenuItems) {
        NSString *strType = [dishInfo objectForKey:@"type"];
        if ([strType isEqualToString:@"main"]) {
            [arrayDishes addObject:dishInfo];
        }
    }
    
    self.mainDishes = (NSArray *)arrayDishes;
}

- (void)getSideDishes:(NSDictionary *)menu {
    NSMutableArray *arrayDishes = [[NSMutableArray alloc] init];
    for (NSDictionary *dishInfo in self.allMenuItems) {
        NSString *strType = [dishInfo objectForKey:@"type"];
        if ([strType isEqualToString:@"side"]) {
            [arrayDishes addObject:dishInfo];
        }
    }
    
    self.sideDishes = (NSArray *)arrayDishes;
}

- (void)getAddons:(NSDictionary *)menu {
    NSMutableArray *arrayDishes = [[NSMutableArray alloc] init];
    for (NSDictionary *dishInfo in self.allMenuItems) {
        NSString *strType = [dishInfo objectForKey:@"type"];
        if ([strType isEqualToString:@"addon"]) {
            [arrayDishes addObject:dishInfo];
        }
    }
    
    self.addons = [(NSArray *)arrayDishes mutableCopy];
}

- (void)setUpTimes:(NSArray *)times {
    NSMutableArray *timeRanges = [@[] mutableCopy];
    
    for (NSDictionary *timeRange in times) {
        
        NSString *startTime = [[BentoShop sharedInstance] convert24To12HoursWithoutAMPM: timeRange[@"start"]];
        NSString *endTime = [[BentoShop sharedInstance] convert24To12HoursWithAMPM: timeRange[@"end"]];
        
        NSString *formattedTimeRange;
        
        NSNumber *availableNum = (NSNumber *)timeRange[@"available"];
        if ([availableNum boolValue]) {
            formattedTimeRange = [NSString stringWithFormat:@"%@-%@", startTime, endTime];
        }
        else {
            formattedTimeRange = [NSString stringWithFormat:@"%@-%@ (sold-out)", startTime, endTime];
        }
    
        [timeRanges addObject: formattedTimeRange];
    }
    
    self.times = timeRanges;
}

- (BOOL)canAddSideDish:(NSInteger)sideDishID
{
    if (self.sideDishes == nil ) {
        return NO;
    }
    
    NSDictionary *dishInfo = [self getSideDish:sideDishID];
    
    if (dishInfo == nil) {
        return NO;
    }
    
    id object = dishInfo[@"max_per_order"];
    if ([object isEqual: [NSNull null]]) {
        return YES;
    }
    
    Bento *bento = [[BentoShop sharedInstance] getCurrentBento];
    NSInteger maxPerOrder = [object integerValue];
    if (bento.indexSideDish1 == sideDishID) {
        maxPerOrder --;
    }
    
    if (bento.indexSideDish2 == sideDishID) {
        maxPerOrder --;
    }
    
    if (bento.indexSideDish3 == sideDishID) {
        maxPerOrder --;
    }
    
    if (bento.indexSideDish4 == sideDishID) {
        maxPerOrder --;
    }
    
    if (maxPerOrder <= 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)canAddDish:(NSInteger)dishID {
    NSInteger quantity = 0;
    
    for (NSDictionary *menuItem in self.allMenuItems) {
        NSInteger itemID;
        
        if (![[menuItem objectForKey:@"itemId"] isEqual:[NSNull null]]) {
            itemID = [[menuItem objectForKey:@"itemId"] integerValue];
        }
        
        if (itemID == dishID) {
            if (![[menuItem objectForKey:@"qty"] isEqual:[NSNull null]])
                quantity = [[menuItem objectForKey:@"qty"] integerValue];
            break;
        }
    }
    
    if (quantity == 0) {
        return YES;
    }
    
    // check how many of the dish already exists in cart
    NSInteger currentAmount = 0;
    
    for (Bento *bento in [BentoShop sharedInstance].aryBentos) {
        if ([bento getMainDish] == dishID) {
            currentAmount ++;
        }
        
        if ([bento getSideDish1] == dishID) {
            currentAmount ++;
        }
        
        if ([bento getSideDish2] == dishID) {
            currentAmount ++;
        }
        
        if ([bento getSideDish3] == dishID) {
            currentAmount ++;
        }
        
        if ([bento getSideDish4] == dishID) {
            currentAmount ++;
        }
    }
    
    if (currentAmount < quantity) {
        return YES;
    }
    
    return NO;
}

- (BOOL)isDishSoldOut:(NSInteger)menuID
{
    if ([[[BentoShop sharedInstance] getAppState] isEqualToString:@"soldout_wall"]) {
        return YES;
    }

    NSInteger quantity;
    
    for (NSDictionary *menuItem in self.allMenuItems) {
        
        NSInteger itemID;
        
        if (![menuItem[@"itemId"] isEqual:[NSNull null]]) {
            itemID = [menuItem[@"itemId"] integerValue];
        }
        
        if (itemID == menuID) {
            
            if (![menuItem[@"qty"] isEqual:[NSNull null]]) {
                quantity = [menuItem[@"qty"] integerValue];
            }
            
            if (quantity > 0) {
                return NO;
            }
            else {
                return YES;
            }
        }
    }

    return NO;
}

- (NSDictionary *)getMainDish:(NSInteger)mainDishID {
    for (NSDictionary *dishInfo in self.mainDishes) {
        
        NSInteger menuIndex = [dishInfo[@"itemId"] integerValue];
        
        if (menuIndex == mainDishID) {
            return dishInfo;
        }
    }
    
    return nil;
}

- (NSDictionary *)getSideDish:(NSInteger)sideDishID {
    
    for (NSDictionary *dishInfo in self.sideDishes) {
        
        NSInteger menuIndex = [dishInfo[@"itemId"] integerValue];
        
        if (menuIndex == sideDishID) {
            return dishInfo;
        }
    }
    
    return nil;
}

@end
