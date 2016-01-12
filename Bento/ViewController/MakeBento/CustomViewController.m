//
//  CustomViewController.m
//  Bento
//
//  Created by Joseph Lau on 1/8/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import "CustomViewController.h"

@interface CustomViewController ()

@end

@implementation CustomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dishBGView.layer.cornerRadius = 2;
    
    self.buildButton.layer.borderWidth = 1;
    self.buildButton.layer.borderColor = [UIColor colorWithRed:0.835f green:0.851f blue:0.851f alpha:1.0f].CGColor;
}

- (IBAction)addMainButtonPressed:(id)sender {
    NSLog(@"add main button pressed");
}

- (IBAction)addSide1ButtonPressed:(id)sender {
    NSLog(@"add side 1 button pressed");
}

- (IBAction)addSide2ButtonPressed:(id)sender {
    NSLog(@"add side 2 button pressed");
}

- (IBAction)addSide3ButtonPressed:(id)sender {
    NSLog(@"add side 3 button pressed");
}

- (IBAction)buildButtonPressed:(id)sender {
    NSLog(@"bottom button pressed");
}


@end
