//
//  BentoBox.h
//  Bento
//
//  Created by Joseph Lau on 11/6/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DishInfo.h"

@interface BentoBox : NSObject

@property (nonatomic) NSMutableArray *items;

- (id)initWithJSON: (NSDictionary *)json;

@end
