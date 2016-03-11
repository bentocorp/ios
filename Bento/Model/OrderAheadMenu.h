//
//  OrderAheadMenu.h
//  Bento
//
//  Created by Joseph Lau on 1/19/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSInteger {
    First,
    Random,
    UseDefault
} DefaultTimeMode;

@interface OrderAheadMenu : NSObject

@property (nonatomic) NSArray *rawTimeRangesArray;

@property (nonatomic) NSString *name;
@property (nonatomic) NSArray *rawTimesArrayForDefaultTimeMode;
@property (nonatomic) NSArray *times;
@property (nonatomic) NSArray *allMenuItems;
@property (nonatomic) NSArray *mainDishes;
@property (nonatomic) NSArray *sideDishes;
@property (nonatomic) NSMutableArray *addons;


@property (nonatomic) NSString *orderType; // hardcode to 2 for order ahead
@property (nonatomic) NSString *mealType;
@property (nonatomic) NSString *kitchen;
@property (nonatomic) NSString *zone;
@property (nonatomic) NSString *forDate;
@property (nonatomic) NSString *menuId;

@property (nonatomic) NSString *scheduledWindowStartTime;
@property (nonatomic) NSString *scheduledWindowEndTime;
@property (nonatomic) NSString *deliveryPrice;

@property (nonatomic) DefaultTimeMode defaultTimeMode;

- (id)initWithDictionary:(NSDictionary *)menu;

- (BOOL)isDishSoldOut:(NSInteger)menuID;

- (BOOL)canAddDish:(NSInteger)dishID;
- (BOOL)canAddSideDish:(NSInteger)sideDishID;

- (NSDictionary *)getMainDish:(NSInteger)mainDishID;
- (NSDictionary *)getSideDish:(NSInteger)sideDishID;

@end
