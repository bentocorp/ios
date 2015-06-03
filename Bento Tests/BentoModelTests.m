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
#import "BentoShop.h"

@interface BentoModelTests : XCTestCase

@end

@implementation BentoModelTests
{
    Bento *bento;
    NSArray *menuStatus;
    NSArray *aryBentos;
}

- (void)setUp {
    [super setUp];
    
    bento = [[Bento alloc] init];
    
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

- (void)testCanAddSideDishYES
{
    BOOL canAddSideDish;
    
    // argument
    NSInteger sideDishID = 54;
    
    /*----------------------------------------------*/
    
    // mock
    NSDictionary *dishInfo = @{
                                @"itemId": @"54",
                                @"name": @"Test Item Name",
                                @"description": @"Test description",
                                @"type": @"main",
                                @"image1": @"https://s3-us-west-1.amazonaws.com/bentonow-assets/menu/041515/hawaiianpoke.jpg",
                                @"max_per_order": @"99" // testing, yes
                             };
    
    if (dishInfo == nil)
        canAddSideDish = NO;
    
    id object = [dishInfo objectForKey:@"max_per_order"];
    if (object == [NSNull null])
        canAddSideDish = YES;
    
    Bento *bentoObject = aryBentos[1];
    
    NSInteger maxPerOrder = [object integerValue];
    if (bentoObject.indexSideDish1 == sideDishID)
        maxPerOrder --;
    
    if (bentoObject.indexSideDish2 == sideDishID)
        maxPerOrder --;
    
    if (bentoObject.indexSideDish3 == sideDishID)
        maxPerOrder --;
    
    if (bentoObject.indexSideDish4 == sideDishID)
        maxPerOrder --;
    
    if (maxPerOrder <= 0)
        canAddSideDish = NO;
    else
        canAddSideDish = YES;
    
    XCTAssert(canAddSideDish == YES, @"Can't add side dish");
}

- (void)testCanAddSideDishNO
{
    BOOL canAddSideDish;
    
    // argument
    NSInteger sideDishID = 54;
    
    /*----------------------------------------------*/
    
    // mock
    NSDictionary *dishInfo = @{
                               @"itemId": @"54",
                               @"name": @"Test Item Name",
                               @"description": @"Test description",
                               @"type": @"main",
                               @"image1": @"https://s3-us-west-1.amazonaws.com/bentonow-assets/menu/041515/hawaiianpoke.jpg",
                               @"max_per_order": @"0" // testing, no
                               };
    
    if (dishInfo == nil)
        canAddSideDish = NO;
    
    id object = [dishInfo objectForKey:@"max_per_order"];
    if (object == [NSNull null])
        canAddSideDish = YES;
    
    Bento *bentoObject = aryBentos[1]; // mock
    
    NSInteger maxPerOrder = [object integerValue];
    if (bentoObject.indexSideDish1 == sideDishID)
        maxPerOrder --;
    
    if (bentoObject.indexSideDish2 == sideDishID)
        maxPerOrder --;
    
    if (bentoObject.indexSideDish3 == sideDishID)
        maxPerOrder --;
    
    if (bentoObject.indexSideDish4 == sideDishID)
        maxPerOrder --;
    
    if (maxPerOrder <= 0)
        canAddSideDish = NO;
    else
        canAddSideDish = YES;
    
    XCTAssert(canAddSideDish == NO, @"Can add side dish");
}

- (void)testGetBentoName
{
    NSString *getBentoName; // return value, argument
    
     Bento *bentoObject = aryBentos[1]; // mock
    
    /*----------------------------------------------*/
    
    if (bentoObject.indexMainDish == 0)
        getBentoName = @"";
    
//    NSDictionary *dishInfo = [[BentoShop sharedInstance] getMainDish:bentoObject.indexMainDish];
    
    NSDictionary *dishInfo = @{
                               @"itemId": @"30",
                               @"name": @"Test Item Name",
                               @"description": @"Test description",
                               @"type": @"main",
                               @"image1": @"https://s3-us-west-1.amazonaws.com/bentonow-assets/menu/041515/hawaiianpoke.jpg",
                               @"max_per_order": @"99"
                               };
    
    if (dishInfo == nil)
        getBentoName = @"";
    
    XCTAssert([[dishInfo objectForKey:@"name"] isEqualToString:@"Test Item Name"], @"Bento name does not exist");
}

@end
