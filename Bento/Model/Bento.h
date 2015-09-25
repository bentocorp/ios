//
//  Bento.h
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+RMArchivable.h"

@interface Bento : NSObject

@property (nonatomic) NSInteger indexMainDish;
@property (nonatomic) NSInteger indexSideDish1;
@property (nonatomic) NSInteger indexSideDish2;
@property (nonatomic) NSInteger indexSideDish3;
@property (nonatomic) NSInteger indexSideDish4;

@property (nonatomic) NSString *hasSoldOutItem;

// Testing
- (NSInteger)getMainDish;
- (NSInteger)getSideDish1;
- (NSInteger)getSideDish2;
- (NSInteger)getSideDish3;
- (NSInteger)getSideDish4;

// Testing
- (void)setMainDish:(NSInteger)indexMainDish;
- (void)setSideDish1:(NSInteger)indexSideDish;
- (void)setSideDish2:(NSInteger)indexSideDish;
- (void)setSideDish3:(NSInteger)indexSideDish;
- (void)setSideDish4:(NSInteger)indexSideDish;

// Not Testing
- (NSString *)getBentoName;

// Testing
- (BOOL)isEmpty;
- (BOOL)isCompleted;
- (void)completeBento:(NSString *)whatNeedsThis;

// Testing
- (BOOL)canAddSideDish:(NSInteger)sideDishID;

- (void)checkIfItemIsSoldOut:(NSInteger)itemID;

@end
