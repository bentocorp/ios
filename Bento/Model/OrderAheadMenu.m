//
//  OrderAheadMenu.m
//  Bento
//
//  Created by Joseph Lau on 1/19/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import "OrderAheadMenu.h"
#import "BentoShop.h"

@implementation OrderAheadMenu

- (id)initWithDictionary:(NSDictionary *)dictionary {
    
    if (self = [super init]) {

        NSString *mealType = dictionary[@"Menu"][@"meal_name"];
        NSString *formattedDate = [[BentoShop sharedInstance] setDateFormat:dictionary[@"for_date"]];
        self.name = [NSString stringWithFormat:@"%@, %@", formattedDate, mealType];
        
        [self getMainDishes:dictionary];
    }
    
    return self;
}

- (void)getMainDishes:(NSDictionary *)menu {
    NSMutableArray *arrayDishes = [[NSMutableArray alloc] init];
    for (NSDictionary *dishInfo in menu[@"MenuItems"]) {
        NSString *strType = [dishInfo objectForKey:@"type"];
        if ([strType isEqualToString:@"main"]) {
            [arrayDishes addObject:dishInfo];
        }
    }
    
    self.mainDishes = (NSArray *)arrayDishes;
}

- (void)getSideDishes:(NSDictionary *)menu {
    NSMutableArray *arrayDishes = [[NSMutableArray alloc] init];
    for (NSDictionary *dishInfo in menu[@"MenuItems"]) {
        NSString *strType = [dishInfo objectForKey:@"type"];
        if ([strType isEqualToString:@"side"]) {
            [arrayDishes addObject:dishInfo];
        }
    }
    
    self.sideDishes = (NSArray *)arrayDishes;
}

- (void)getAddons:(NSDictionary *)menu {
    NSMutableArray *arrayDishes = [[NSMutableArray alloc] init];
    for (NSDictionary *dishInfo in menu[@"MenuItems"]) {
        NSString *strType = [dishInfo objectForKey:@"type"];
        if ([strType isEqualToString:@"addon"]) {
            [arrayDishes addObject:dishInfo];
        }
    }
    
    self.addons = (NSArray *)arrayDishes;
}

@end
