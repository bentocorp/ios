//
//  Addon.h
//  Bento
//
//  Created by Joseph Lau on 11/17/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Addon : NSObject

@property (nonatomic) NSString *type;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *descript;
@property (nonatomic) float price;
@property (nonatomic) NSString *image1;
@property (nonatomic) int itemId;
@property (nonatomic) int maxPerOrder;



@end
