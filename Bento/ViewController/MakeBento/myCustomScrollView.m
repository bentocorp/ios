//
//  myCustomScrollView.m
//  Bento
//
//  Created by Joseph Lau on 5/18/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "myCustomScrollView.h"

@implementation myCustomScrollView

- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
    NSLog(@"touchesShouldCancelInContentView");
    
    if ([view isKindOfClass:[UIButton class]])
        return NO;
    else
        return YES;
}

@end
