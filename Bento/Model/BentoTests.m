//
//  BentoTests.m
//  Bento
//
//  Created by Joseph Lau on 5/21/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "Bento.h"

@interface BentoTests : XCTestCase

@end

@implementation BentoTests
{
    Bento *vcToTest;
}

- (void)setUp
{
    [super setUp];
    
    vcToTest = [[Bento alloc] init];
}

- (void)tearDown
{
    [super tearDown];
}


@end
