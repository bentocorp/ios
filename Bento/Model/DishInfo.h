//
//  DishInfo.h
//  Bento
//
//  Created by Joseph Lau on 11/6/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DishInfo : NSObject

typedef enum : NSInteger {
    Main,
    Side,
    AddOn,
} Type;

@property (nonatomic) NSInteger dishId;
@property (nonatomic) NSString *label;
@property (nonatomic) NSString *name;
@property (nonatomic) Type type;

- (id)initWithJSON: (NSDictionary *)json;

@end
