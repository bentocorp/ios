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
    // set argument to see if it can be added
    NSInteger dishID = 43;
    
    // Mock
    NSArray *menuStatus = @[
                                @{
                                    @"itemId": @"30",
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
                                    @"qty": @"99" // right here
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
    
    NSArray *aryBentos = @[bento1, bento2];
    
    BOOL canAddDish;
    
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
    
    NSLog(@"QUANTITY: %ld", quantity);

    if (quantity == 0) // wtf?
        canAddDish = YES;

    // check to see how many of the dishID(from argument) already exists in cart
    NSInteger currentAmount = 0;
    for (Bento *bento in aryBentos)
    {
        if ([bento getMainDish] == dishID)
            currentAmount ++;
        
        if ([bento getSideDish1] == dishID)
            currentAmount ++;
        
        if ([bento getSideDish2] == dishID)
            currentAmount ++;
        
        if ([bento getSideDish3] == dishID)
            currentAmount ++;
        
        if ([bento getSideDish4] == dishID)
            currentAmount ++;
    }
    
    XCTAssert(currentAmount < quantity == YES, @"Can't add dish");
}

- (void)testCanAddDishNO
{
    // set argument to see if it can be added
    NSInteger dishID = 30;
    
    // Mock
    NSArray *menuStatus = @[
                            @{
                                @"itemId": @"30",
                                @"qty": @"0" // checking this
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
    
    NSArray *aryBentos = @[bento1, bento2];
    
    BOOL canAddDish;
    
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
    
    NSLog(@"QUANTITY: %ld", quantity);
    
    if (quantity == 0) // wtf?
        canAddDish = YES;
    
    // check to see how many of the dishID(from argument) already exists in cart
    NSInteger currentAmount = 0;
    for (Bento *bento in aryBentos)
    {
        if ([bento getMainDish] == dishID)
            currentAmount ++;
        
        if ([bento getSideDish1] == dishID)
            currentAmount ++;
        
        if ([bento getSideDish2] == dishID)
            currentAmount ++;
        
        if ([bento getSideDish3] == dishID)
            currentAmount ++;
        
        if ([bento getSideDish4] == dishID)
            currentAmount ++;
    }
    
    XCTAssert(currentAmount < quantity == NO, @"Can add dish");
}

- (void)testCanAddSideDishYES
{
    
}

- (void)testCanAddSideDishNO
{
    
}

@end
