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

- (void)testCanAddSideDishYES
{
    BOOL canAddSideDish;
    
    // argument
    NSInteger sideDishID = 54;
    
    /*----------------------------------------------*/
    
//    NSDictionary *dishInfo = [[BentoShop sharedInstance] getSideDish:sideDishID];
    
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
    
//    NSDictionary *dishInfo = [[BentoShop sharedInstance] getSideDish:sideDishID];
    
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
