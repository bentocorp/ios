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
{
    NSDictionary *dicStatus1;
    NSDictionary *dicStatus2;
}

- (void)setUp {
    [super setUp];
    
    // mock CLOSED
    dicStatus1 = @{
                    @"menu": @[
                                @{
                                    @"itemId": @"25",
                                    @"qty": @"9"
                                },
                                @{
                                    @"itemId": @"35",
                                    @"qty": @"9"
                                },
                                @{
                                    @"itemId": @"39",
                                    @"qty": @"9"
                                },
                                @{
                                    @"itemId": @"42",
                                    @"qty": @"9"
                                },
                                @{
                                    @"itemId": @"51",
                                    @"qty": @"9"
                                },
                                @{
                                    @"itemId": @"52",
                                    @"qty": @"9"
                                }
                             ],
                    @"overall": @{
                                    @"value": @"closed"
                                 }
                    };
    
    // mock SOLD OUT
    dicStatus2 = @{
                   @"menu": @[
                               @{
                                   @"itemId": @"25",
                                   @"qty": @"9"
                                },
                               @{
                                   @"itemId": @"35",
                                   @"qty": @"9"
                                },
                               @{
                                   @"itemId": @"39",
                                   @"qty": @"9"
                                },
                               @{
                                   @"itemId": @"42",
                                   @"qty": @"9"
                                },
                               @{
                                   @"itemId": @"51",
                                   @"qty": @"9"
                                },
                               @{
                                   @"itemId": @"52",
                                   @"qty": @"9"
                                }
                             ],
                    @"overall": @{
                                   @"value": @"sold out"
                                 }
                   };
}

- (void)tearDown {
    [super tearDown];
}

- (void)testIsClosedYES
{
    BOOL isClosed;
    
    /*----------------------------------------*/
    
    NSString *strOverallStatus = dicStatus1[@"overall"][@"value"];
    
    if ([strOverallStatus isEqualToString:@"closed"])
        isClosed = YES;
    else
        isClosed = NO;

    XCTAssert(isClosed == YES, @"It's not closed!");
}

- (void)testIsClosedNO
{
    BOOL isClosed;
    
    /*----------------------------------------*/
    
    NSString *strOverallStatus = dicStatus2[@"overall"][@"value"];
    
    if ([strOverallStatus isEqualToString:@"closed"])
        isClosed = YES;
    else
        isClosed = NO;
    
    XCTAssert(isClosed == NO, @"It's open!");
}

- (void)testIsSoldOutYES
{
    BOOL isSoldOut;
    
    /*----------------------------------------*/
    
    if (dicStatus2 == nil)
        isSoldOut = YES;
    
    NSString *strOverallStatus = dicStatus2[@"overall"][@"value"];
    if ([strOverallStatus isEqualToString:@"sold out"])
        isSoldOut = YES;
    else
        isSoldOut = NO;
    
    XCTAssert(isSoldOut == YES, @"It's not sold out!");
}

- (void)testIsSoldOutNO
{
    BOOL isSoldOut;
    
    /*----------------------------------------*/
    
    if (dicStatus1 == nil)
        isSoldOut = YES;
    
    NSString *strOverallStatus = dicStatus1[@"overall"][@"value"];
    if ([strOverallStatus isEqualToString:@"sold out"])
        isSoldOut = YES;
    else
        isSoldOut = NO;
    
    XCTAssert(isSoldOut == NO, @"It's sold out!");
}

@end
