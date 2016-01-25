//
//  FiveCustomViewController.m
//  Bento
//
//  Created by Joseph Lau on 1/13/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#import "FiveCustomViewController.h"
#import "CAGradientLayer+SJSGradients.h"

@interface FiveCustomViewController ()

@end

@implementation FiveCustomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /*---Dish BG View---*/
    self.dishBGView.layer.cornerRadius = 2;
    
    /*---Dish Image Views*/
    [self.mainDishImageView setClipsToBounds:YES];
    [self.sideDish1ImageView setClipsToBounds:YES];
    [self.sideDish2Imageview setClipsToBounds:YES];
    [self.sideDish3ImageView setClipsToBounds:YES];
    [self.sideDish4ImageView setClipsToBounds:YES];
    
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
    
    backgroundLayer = [CAGradientLayer blackGradientLayer];
    backgroundLayer.frame = self.sideDish3ImageView.frame;
    backgroundLayer.opacity = 0.8f;
    [self.sideDish4ImageView.layer insertSublayer:backgroundLayer atIndex:0];
    
    /*---Build Button---*/
    UIColor *borderColor = [UIColor colorWithRed:0.835f green:0.851f blue:0.851f alpha:1.0f];
    
    self.buildButton.layer.borderWidth = 1;
    self.buildButton.layer.borderColor = borderColor.CGColor;
    
    /*---View Add-ons Button---*/
    [self setViewAddonsWidthConstraint];
    self.viewAddonsButton.layer.borderWidth = 1;
    self.viewAddonsButton.layer.borderColor = borderColor.CGColor;
    
    NSString *strTitle = @"VIEW ADD-ONS";
    if (strTitle != nil) {
        // Add Another Bento Button
        NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
        float spacing = 1.0f;
        [attributedTitle addAttribute:NSKernAttributeName
                                value:@(spacing)
                                range:NSMakeRange(0, [strTitle length])];
        [self.viewAddonsButton setAttributedTitle:attributedTitle forState:UIControlStateNormal];
    }
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

- (IBAction)addSide4ButtonPressed:(id)sender {
    [self.delegate customVCAddSideDish4Pressed:sender];
}

- (IBAction)buildButtonPressed:(id)sender {
    [self.delegate customVCBuildButtonPressed:sender];
}

- (IBAction)viewAddonsButtonPressed:(id)sender {
    [self.delegate customVCViewAddonsButtonPressed:sender];
}

- (void)setViewAddonsWidthConstraint {
    NSLayoutConstraint *viewAddonsButtonWidthConstraint = [NSLayoutConstraint constraintWithItem:self.viewAddonsButton
                                                                                       attribute:NSLayoutAttributeWidth
                                                                                       relatedBy:0
                                                                                          toItem:nil
                                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                                      multiplier:1
                                                                                        constant:SCREEN_WIDTH/2-5];
    [self.view addConstraint:viewAddonsButtonWidthConstraint];
}

@end
