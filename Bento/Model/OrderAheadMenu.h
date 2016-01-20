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
@property (nonatomic) NSArray *allMenuItems;
@property (nonatomic) NSArray *mainDishes;
@property (nonatomic) NSArray *sideDishes;
@property (nonatomic) NSMutableArray *addons;

- (id)initWithDictionary:(NSDictionary *)menu;

- (BOOL)isDishSoldOut:(NSInteger)menuID;

- (BOOL)canAddDish:(NSInteger)dishID;
- (BOOL)canAddSideDish:(NSInteger)sideDishID;

- (NSDictionary *)getMainDish:(NSInteger)mainDishID;
- (NSDictionary *)getSideDish:(NSInteger)sideDishID;

@end
