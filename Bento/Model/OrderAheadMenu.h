//
//  OrderAheadMenu.h
//  Bento
//
//  Created by Joseph Lau on 1/19/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OrderAheadMenu : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSArray *times;
@property (nonatomic) NSArray *deliveryPrices;
@property (nonatomic) NSArray *allMenuItems;
@property (nonatomic) NSArray *mainDishes;
@property (nonatomic) NSArray *sideDishes;
@property (nonatomic) NSMutableArray *addons;

@property (nonatomic) NSString *mealType;
@property (nonatomic) NSString *kitchen;
@property (nonatomic) NSString *zone;
@property (nonatomic) NSString *forDate;
@property (nonatomic) NSString *menuId;

@property (nonatomic) NSString *scheduledWindowStartTime;
@property (nonatomic) NSString *scheduledWindowEndTime;

@property (nonatomic) NSString *deliveryPriceString;

- (id)initWithDictionary:(NSDictionary *)menu;

- (BOOL)isDishSoldOut:(NSInteger)menuID;

- (BOOL)canAddDish:(NSInteger)dishID;
- (BOOL)canAddSideDish:(NSInteger)sideDishID;

- (NSDictionary *)getMainDish:(NSInteger)mainDishID;
- (NSDictionary *)getSideDish:(NSInteger)sideDishID;

@end
