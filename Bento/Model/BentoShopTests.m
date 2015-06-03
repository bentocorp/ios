//
//  BentoShopTests.m
//  Bento
//
//  Created by Joseph Lau on 5/22/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "BentoShop.h"

@interface BentoShopTests : XCTestCase

@end

@implementation BentoShopTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testIsClosedYES
{
    BOOL isClosed;
    
    NSString *strOverallStatus = @"closed"; // mock
    
    if ([strOverallStatus isEqualToString:@"closed"])
        isClosed = YES;
    else
        isClosed = NO;

    XCTAssert(isClosed == YES, @"It's not closed!");
}

- (void)testIsClosedNO
{
    BOOL isClosed;
    
    NSString *strOverallStatus = @"open"; // mock
    
    if ([strOverallStatus isEqualToString:@"closed"])
        isClosed = YES;
    else
        isClosed = NO;
    
    XCTAssert(isClosed == NO, @"It's open!");
}

- (void)testIsSoldOut
{
    if (self.dicStatus == nil)
        return YES;
    
    NSString *strOverallStatus = self.dicStatus[@"overall"][@"value"];
    if ([strOverallStatus isEqualToString:@"sold out"])
        return YES;
    
    return NO;
}

@end
