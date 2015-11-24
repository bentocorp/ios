//
//  Addon.h
//  Bento
//
//  Created by Joseph Lau on 11/17/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Addon : NSObject

@property (nonatomic) NSInteger itemId;
@property (nonatomic) NSInteger qty;
@property (nonatomic) float unitPrice;

- (id)initWithDictionary:(NSDictionary *)dictionary quantity:(NSInteger)quantity;
- (void)addItem;
- (void)removeItem;

@end
