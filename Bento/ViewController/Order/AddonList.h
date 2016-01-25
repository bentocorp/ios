//
//  AddonList.h
//  Bento
//
//  Created by Joseph Lau on 11/17/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AddonList : NSObject

@property (nonatomic) NSMutableArray *addonList;

+ (AddonList *)sharedInstance;
- (void)saveList;
- (void)emptyList;
- (void)removeFromList:(NSInteger)index;
- (NSInteger)getTotalCount;

@end
