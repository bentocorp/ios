//
//  BentoDev_Tests.m
//  BentoDev Tests
//
//  Created by Joseph Lau on 5/21/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Bento.h"
#import "BentoShop.h"

@interface BentoDev_Tests : XCTestCase

@end

@implementation BentoDev_Tests
{
    Bento *emptyBento;
    Bento *incompleteBento;
    Bento *completeBento;
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    [emptyBento setMainDish:0];
    [emptyBento setSideDish1:0];
    [emptyBento setSideDish2:0];
    [emptyBento setSideDish3:0];
    [emptyBento setSideDish4:0];
    
    [incompleteBento setMainDish:1];
    [incompleteBento setSideDish1:0];
    [incompleteBento setSideDish2:0];
    [incompleteBento setSideDish3:0];
    [incompleteBento setSideDish4:0];
    
    [completeBento setMainDish:2];
    [completeBento setSideDish1:2];
    [completeBento setSideDish2:2];
    [completeBento setSideDish3:2];
    [completeBento setSideDish4:2];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testIsEmptyYes
{
    BOOL isEmpty = [emptyBento isEmpty];
    NSLog(@"main - %d", isEmpty);
    XCTAssertTrue(isEmpty, @"It's not empty!");
}

@end
