//
//  CustomViewController.m
//  Bento
//
//  Created by Joseph Lau on 1/8/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import "CustomViewController.h"
#import "CAGradientLayer+SJSGradients.h"

@interface CustomViewController ()

@end

@implementation CustomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /*---Dish BG View---*/
    self.dishBGView.layer.cornerRadius = 2;
    
    /*---Dish Image Views*/
    [self.mainDishImageView setClipsToBounds:YES];
    [self.sideDish1ImageView setClipsToBounds:YES];
    [self.sideDish2Imageview setClipsToBounds:YES];
    [self.sideDish3ImageView setClipsToBounds:YES];
    
    /*---Gradient Layer---*/
    CAGradientLayer *backgroundLayer = [CAGradientLayer blackGradientLayer];
    backgroundLayer.frame = self.mainDishImageView.frame;
    backgroundLayer.opacity = 0.8f;
    [self.mainDishImageView.layer insertSublayer:backgroundLayer atIndex:0];
    
    backgroundLayer = [CAGradientLayer blackGradientLayer];
    backgroundLayer.frame = self.sideDish1ImageView.frame;
    backgroundLayer.opacity = 0.8f;
    [self.sideDish1ImageView.layer insertSublayer:backgroundLayer atIndex:0];
    
    backgroundLayer = [CAGradientLayer blackGradientLayer];
    backgroundLayer.frame = self.sideDish2Imageview.frame;
    backgroundLayer.opacity = 0.8f;
    [self.sideDish2Imageview.layer insertSublayer:backgroundLayer atIndex:0];
    
    backgroundLayer = [CAGradientLayer blackGradientLayer];
    backgroundLayer.frame = self.sideDish3ImageView.frame;
    backgroundLayer.opacity = 0.8f;
    [self.sideDish3ImageView.layer insertSublayer:backgroundLayer atIndex:0];
    
    /*---Build Button---*/
    self.buildButton.layer.borderWidth = 1;
    self.buildButton.layer.borderColor = [UIColor colorWithRed:0.835f green:0.851f blue:0.851f alpha:1.0f].CGColor;
}

#pragma mark Button Events
- (IBAction)addMainButtonPressed:(id)sender {
    [self.delegate customVCAddMainButtonPressed:sender];
}

- (IBAction)addSide1ButtonPressed:(id)sender {
    [self.delegate customVCAddSideDish1Pressed:sender];
}

- (IBAction)addSide2ButtonPressed:(id)sender {
    [self.delegate customVCAddSideDish2Pressed:sender];
}

- (IBAction)addSide3ButtonPressed:(id)sender {
    [self.delegate customVCAddSideDish3Pressed:sender];
}

- (IBAction)buildButtonPressed:(id)sender {
    [self.delegate customVCBuildButtonPressed:sender];
}

@end
