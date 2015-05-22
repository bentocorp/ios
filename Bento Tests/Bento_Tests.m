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

- (void)testSetMainDish
{
    // Dish Int
    NSInteger mainDishInt = 35;
    
    // Set Dish Int to Bento
    [bento setMainDish:mainDishInt];

    XCTAssert(mainDishInt == [bento getMainDish], @"Did not set main dish int correctly!");
}

@end
