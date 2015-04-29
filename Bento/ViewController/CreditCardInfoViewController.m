//
//  CreditCardInfoViewController.m
//  settings
//
//  Created by Joseph Lau on 4/23/15.
//  Copyright (c) 2015 Joseph Lau. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#import "CreditCardInfoViewController.h"
#import "DataManager.h"

@interface CreditCardInfoViewController ()

@end

@implementation CreditCardInfoViewController
{
    NSDictionary *currentUserInfo;
    
    UIImageView *creditCardImage;
    UILabel *creditCardDigitsLabel;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    currentUserInfo = [[DataManager shareDataManager] getUserInfo];

    self.view.backgroundColor = [UIColor colorWithRed:0.914f green:0.925f blue:0.925f alpha:1.0f];
    
    // navigation bar color
    UIView *navigationBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 65)];
    navigationBarView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navigationBarView];
    
    // title label
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 2 - 110, 20, 220, 45)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    titleLabel.textColor = [UIColor colorWithRed:0.341f green:0.376f blue:0.439f alpha:1.0f];
    titleLabel.text = @"Credit Card";
    [self.view addSubview:titleLabel];
    
    // back button
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 50, 45)];
    [backButton setImage:[UIImage imageNamed:@"nav_btn_back"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(onBackButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
    
    // line separators
    UIView *longLineSepartor1 = [[UIView alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, 1)];
    longLineSepartor1.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
    [self.view addSubview:longLineSepartor1];
    
    UIView *longLineSepartor2 = [[UIView alloc] initWithFrame:CGRectMake(0, 144, SCREEN_WIDTH, 1)];
    longLineSepartor2.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
    [self.view addSubview:longLineSepartor2];
    
    UIView *longLineSepartor3 = [[UIView alloc] initWithFrame:CGRectMake(0, 190, SCREEN_WIDTH, 1)];
    longLineSepartor3.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
    [self.view addSubview:longLineSepartor3];
    
    // white background view
    UIView *whiteBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 145, SCREEN_WIDTH, 45)];
    whiteBackgroundView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:whiteBackgroundView];

    // credit card image
    creditCardImage = [[UIImageView alloc] initWithFrame:CGRectMake(20, 11.5, 30, 22)];
    [whiteBackgroundView addSubview:creditCardImage];
    
    // credit card digits
    creditCardDigitsLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 12, 150, 21)];
    creditCardDigitsLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    creditCardDigitsLabel.textColor = [UIColor colorWithRed:0.341f green:0.376f blue:0.439f alpha:1.0f];
    [whiteBackgroundView addSubview:creditCardDigitsLabel];
}

-(void)viewWillAppear:(BOOL)animated
{
    if ([currentUserInfo[@"card"] isKindOfClass:[NSNull class]]) {
        
        // no card info
        creditCardImage.image = [UIImage imageNamed:@"placeholder"];
        
    } else {
        
        // has card info
        creditCardImage.image = [UIImage imageNamed:[currentUserInfo[@"card"][@"brand"] lowercaseString]];
        creditCardDigitsLabel.text = currentUserInfo[@"card"][@"last4"];
    }
}

-(void)onBackButton
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
