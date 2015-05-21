//
//  BentoTests.m
//  BentoTests
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface BentoTests : XCTestCase

@end

@implementation BentoTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testTrue
{
    XCTAssertTrue(true, @"Expression was not true");
}

- (void)testFalse
{
    int val1 = 1;
    int val2 = 2;
    XCTAssertFalse(val1 == val2, @"%d == %d", val1, val2);
}

- (void)testStringForNil
{
    NSString *somestring;
    XCTAssertNil(somestring, @"someString was not nil");
}

- (void)testStringForNotNil
{
    NSString *someString = @"workshop";
    XCTAssertNotNil(someString, @"someString == '%@'", someString);
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
