//
//  Bento_Tests.m
//  Bento Tests
//
//  Created by Joseph Lau on 5/21/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Bento.h"
#import "BentoShop.h"

@interface Bento_Tests : XCTestCase

@end

@implementation Bento_Tests
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
    XCTAssert([bento isEmpty] == YES, @"Bento is still empty!");
}

- (void)testIsEmptyNO
{
    [bento setMainDish:1];
    [bento setSideDish1:1];
    [bento setSideDish2:1];
    [bento setSideDish3:1];
    [bento setSideDish4:1];
    
    XCTAssert([bento isEmpty] == NO, @"Bento is still empty!");
}

- (void)testIsCompletedYES
{
    [bento setMainDish:1];
    [bento setSideDish1:1];
    [bento setSideDish2:1];
    [bento setSideDish3:1];
    [bento setSideDish4:1];
    
    XCTAssert([bento isCompleted] == YES, @"Bento is not complete!");
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

// how the fuck do you test getbentoname??



@end
