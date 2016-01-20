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

@property (nonatomic) NSArray *mainDishes;
@property (nonatomic) NSArray *sideDishes;
@property (nonatomic) NSArray *addons;

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (BOOL)isDishSoldOut:(NSInteger)menuID;
- (BOOL)canAddSideDish:(NSInteger)sideDishID;

@end
