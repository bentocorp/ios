//
//  BentoModelTests.m
//  Bento
//
//  Created by Joseph Lau on 5/22/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Bento.h"

@interface BentoModelTests : XCTestCase

@end

@implementation BentoModelTests
{
    Bento *bento;
}

- (void)setUp {
    [super setUp];
    
    bento = [[Bento alloc] init];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testSetAndGetMainDish
{
    // Dish Int
    NSInteger mainDishInt = 35;
    
    // Set Dish Int to Bento
    [bento setMainDish:mainDishInt];
    
    XCTAssert(mainDishInt == [bento getMainDish], @"Did not set/get main dish int correctly!");
}

- (void)testSetAndGetSideDish // same for all 4 sides
{
    // Dish Int
    NSInteger sideDishInt = 22;
    
    // Set Dish Int to Beno
    [bento setSideDish1:sideDishInt];
    
    XCTAssert(sideDishInt == [bento getSideDish1], @"Did not set/get side dish int correctly!");
}

- (void)testIsEmptyYES
{
    XCTAssert([bento isEmpty] == YES, @"Bento is not empty!");
}

- (void)testIsEmptyNO
{
    [bento setMainDish:1];
    [bento setSideDish1:1];
    [bento setSideDish2:1];
    [bento setSideDish3:1];
    [bento setSideDish4:1];
    
    XCTAssert([bento isEmpty] == NO, @"Bento is empty!");
}

- (void)testIsCompletedYES
{
    [bento setMainDish:1];
    [bento setSideDish1:1];
    [bento setSideDish2:1];
    [bento setSideDish3:1];
    [bento setSideDish4:1];
    
    XCTAssert([bento isCompleted] == YES, @"Bento is incomplete!");
}

- (void)testIsCompletedNO
{
    [bento setMainDish:1];
    [bento setSideDish1:1];
    [bento setSideDish2:1];
    [bento setSideDish3:0];
    [bento setSideDish4:0];
    
    XCTAssert([bento isCompleted] == NO, @"Bento is complete!");
}

- (void)testCanAddDishYES
{
    BOOL canAddDish;
    
    // Mock
    NSArray *menuStatus = @[
                                @{
                                    @"itemId": @"2",
                                    @"qty": @"99"
                                },
                                @{
                                    @"itemId": @"38",
                                    @"qty": @"99"
                                },
                                @{
                                    @"itemId": @"41",
                                    @"qty": @"99"
                                },
                                @{
                                    @"itemId": @"43",
                                    @"qty": @"99"
                                },
                                @{
                                    @"itemId": @"49",
                                    @"qty": @"99"
                                },
                                @{
                                    @"itemId": @"54",
                                    @"qty": @"99"
                                }
                           ];
    ////////////////////////////////////////////////
    
//    NSInteger quantity = 0;
//    for (NSDictionary *menuItem in menuStatus)
//    {
//        NSInteger itemID;
//        
//        // get itemID
//        if (![[menuItem objectForKey:@"itemId"] isEqual:[NSNull null]])
//            itemID = [[menuItem objectForKey:@"itemId"] integerValue];
//        
//        // if selected dish id matches item id
//        if (itemID == dishID)
//        {
//            // get the quantity of it
//            if (![[menuItem objectForKey:@"qty"] isEqual:[NSNull null]])
//                quantity = [[menuItem objectForKey:@"qty"] integerValue];
//            break;
//        }
//    }
//    
//    if (quantity == 0)
//        canAddDish = YES;
//    
//    // check if how many of the dish exists in cart
//    NSInteger currentAmount = 0;
//    for (Bento *bento in self.aryBentos)
//    {
//        if ([bento getMainDish] == dishID)
//            currentAmount ++;
//        
//        if ([bento getSideDish1] == dishID)
//            currentAmount ++;
//        
//        if ([bento getSideDish2] == dishID)
//            currentAmount ++;
//        
//        if ([bento getSideDish3] == dishID)
//            currentAmount ++;
//        
//        if ([bento getSideDish4] == dishID)
//            currentAmount ++;
//    }
//    
//    // if the amount in cart is less than quantity, then ok to add
//    if (currentAmount < quantity)
//        canAddDish = YES;
//    
//    // can't add
//    canAddDish = NO;
}

- (void)testCanAddDishNO
{
    
}

- (void)testCanAddSideDishYES
{
    
}

- (void)testCanAddSideDishNO
{
    
}

@end
