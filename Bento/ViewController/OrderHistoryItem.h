//
//  OrderHistoryItem.h
//  Bento
//
//  Created by Joseph Lau on 1/22/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OrderHistoryItem : NSObject

@property (nonatomic) NSString *title;
@property (nonatomic) NSString *price;
@property (nonatomic) NSString *driverId;
@property (nonatomic) float lat;
@property (nonatomic) float lng;
@property (nonatomic) NSString *orderId;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
