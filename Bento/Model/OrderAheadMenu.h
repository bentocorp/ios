//
//  OrderAheadMenu.h
//  Bento
//
//  Created by Joseph Lau on 1/19/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OrderAheadMenu : NSObject

- (id)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic) NSString *name;
@property (nonatomic) NSArray *times;

@property (nonatomic) NSArray *mainDishes;
@property (nonatomic) NSArray *sideDishes;
@property (nonatomic) NSArray *addons;

@end
