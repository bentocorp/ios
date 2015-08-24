//
//  KifTests.m
//  Bento
//
//  Created by Joseph Lau on 8/20/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#define SETTINGS_BUTTON     @"Settings Button"

#import "KifTests.h"

@implementation KifTests

- (void)testSettings
{
    [tester waitForTappableViewWithAccessibilityLabel:SETTINGS_BUTTON];
    [tester tapViewWithAccessibilityLabel:SETTINGS_BUTTON];
}

@end

/* 
 
The 3 most common things you'd do with KIF are:
 
 1) tap a view
 2) enter text into a view
 3) wait for a view to appear
 
Note: you can write other methods that are called inside the tests
 
Note: In their normal use, Accessibility Labels are used by iOS to identify UI elements to voice-over users, generally to assist people with visual impairments. KIF uses the Accessibility Label property to identify UI elements that can interact with. Without one, KIF won't be able to observe or interact with it. Keep the strings in human readable format, so it also has the benefit of being useful as an Accessbility Label.
 
*/
