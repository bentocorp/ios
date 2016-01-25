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
    
    NSArray *menuStatus;
    NSArray *aryBentos;
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
    
    // Mock
    menuStatus = @[
                   @{
                       @"itemId": @"30",
                       @"qty": @"0" // testing, result NO
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
                       @"qty": @"99" // testing, result YES
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
    
    Bento *bento1 = [Bento new];
    bento1.indexMainDish = 30;
    bento1.indexSideDish1 = 38;
    bento1.indexSideDish2 = 41;
    bento1.indexSideDish3 = 43;
    bento1.indexSideDish4 = 49;
    
    Bento *bento2 = [Bento new];
    bento2.indexMainDish = 30;
    bento2.indexSideDish1 = 38;
    bento2.indexSideDish2 = 38;
    bento2.indexSideDish3 = 43;
    bento2.indexSideDish4 = 54;
    
    aryBentos = @[bento1, bento2];

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

- (void)testCanAddDishYES
{
    BOOL canAddDish;
    
    // set argument as 43, can we add 43?
    NSInteger dishID = 43;
    
    /*----------------------------------------------*/
    
    NSInteger quantity = 0; // how many qty left?
    
    for (NSDictionary *menuItem in menuStatus)
    {
        NSInteger itemID; // resets everytime
        
        // if returned value from itemId is not null...
        if (![[menuItem objectForKey:@"itemId"] isEqual:[NSNull null]])
            itemID = [[menuItem objectForKey:@"itemId"] integerValue]; // ...get itemId and convert to integer value, 43
        
        // if selected dish id matches item id
        if (itemID == dishID)
        {
            // if returned value from gty is not null...
            if (![[menuItem objectForKey:@"qty"] isEqual:[NSNull null]])
                quantity = [[menuItem objectForKey:@"qty"] integerValue]; // ...get qty and convert to integer value, 99
            
            break; // stop searching for qty once found match itemID and dishItem
        }
    }
    
    if (quantity == 0) // wtf?
        canAddDish = YES;
    
    // check to see how many of the dishID(from argument) already exists in cart
    NSInteger currentAmount = 0;
    
    for (Bento *bentoObject in aryBentos)
    {
        if ([bentoObject getMainDish] == dishID)
            currentAmount ++;
        
        if ([bentoObject getSideDish1] == dishID)
            currentAmount ++;
        
        if ([bentoObject getSideDish2] == dishID)
            currentAmount ++;
        
        if ([bentoObject getSideDish3] == dishID)
            currentAmount ++;
        
        if ([bentoObject getSideDish4] == dishID)
            currentAmount ++;
    }
    
    canAddDish = currentAmount < quantity;
    
    XCTAssert(canAddDish == YES, @"Can't add dish");
}

- (void)testCanAddDishNO
{
    BOOL canAddDish;
    
    // set argument to see if it can be added
    NSInteger dishID = 30;
    
    /*----------------------------------------------*/
    
    NSInteger quantity = 0; // how many qty left?
    
    for (NSDictionary *menuItem in menuStatus)
    {
        NSInteger itemID; // resets everytime
        
        // if returned value from itemId is not null...
        if (![[menuItem objectForKey:@"itemId"] isEqual:[NSNull null]])
            itemID = [[menuItem objectForKey:@"itemId"] integerValue]; // ...get itemId and convert to integer value, 43
        
        // if selected dish id matches item id
        if (itemID == dishID)
        {
            // if returned value from gty is not null...
            if (![[menuItem objectForKey:@"qty"] isEqual:[NSNull null]])
                quantity = [[menuItem objectForKey:@"qty"] integerValue]; // ...get qty and convert to integer value, 99
            
            break; // stop searching for qty once found match itemID and dishItem
        }
    }
    
    if (quantity == 0) // wtf?
        canAddDish = YES;
    
    // check to see how many of the dishID(from argument) already exists in cart
    NSInteger currentAmount = 0;
    
    for (Bento *bentoObject in aryBentos)
    {
        if ([bentoObject getMainDish] == dishID)
            currentAmount ++;
        
        if ([bentoObject getSideDish1] == dishID)
            currentAmount ++;
        
        if ([bentoObject getSideDish2] == dishID)
            currentAmount ++;
        
        if ([bentoObject getSideDish3] == dishID)
            currentAmount ++;
        
        if ([bentoObject getSideDish4] == dishID)
            currentAmount ++;
    }
    
    canAddDish = currentAmount < quantity;
    
    XCTAssert(canAddDish == NO, @"Can add dish");
}


@end
