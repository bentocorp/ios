//
//  StatusViewController.m
//  Bento
//
//  Created by Joseph Lau on 2/23/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import "StatusViewController.h"

@interface StatusViewController ()

@end

@implementation StatusViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dotView.layer.cornerRadius = 3;
    self.dotView.layer.masksToBounds = YES;
}

@end
