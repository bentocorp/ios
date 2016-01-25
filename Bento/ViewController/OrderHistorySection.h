//
//  OrderHistorySection.h
//  Bento
//
//  Created by Joseph Lau on 1/22/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OrderHistorySection : NSObject

@property (nonatomic) NSString *sectionTitle;
@property (nonatomic) NSMutableArray *items;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
