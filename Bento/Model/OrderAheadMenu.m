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
        
        NSString *formattedDate = [[BentoShop sharedInstance] setDateFormat:dictionary[@"Menu"][@"for_date"]];
        
        self.name = [NSString stringWithFormat:@"%@, %@", formattedDate, [NSString stringWithFormat:@"%@%@",[[mealType substringToIndex:1] uppercaseString], [mealType substringFromIndex:1]]];
        
        [self getMainDishes:dictionary];
        [self getSideDishes:dictionary];
        [self getAddons:dictionary];
        [self setUpTimes:dictionary[@"Times"]];
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

@end
