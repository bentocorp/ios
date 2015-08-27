//
//  NetworkErrorViewController.m
//  Bento
//
//  Created by Joseph Lau on 5/26/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#import "NetworkErrorViewController.h"
#import "DataManager.h"
#import "BentoShop.h"
#import "UIImageView+WebCache.h"
#import "AppDelegate.h"
#import "JGProgressHUD.h"
#import "UIColor+CustomColors.h"

@interface NetworkErrorViewController ()

@end

@implementation NetworkErrorViewController
{
    UIImageView *ivBackground;
//    UIAlertView *alert;
    BentoShop *globalShop;
    BOOL isConnected;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    globalShop = [BentoShop sharedInstance];
    
    UIColor *color1 = [UIColor bentoGradient1];
    UIColor *color2 = [UIColor bentoGradient2];
    
    ivBackground = [[UIImageView alloc] initWithFrame:self.view.bounds];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = ivBackground.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[color1 CGColor], (id)[color2 CGColor], nil];
    
    NSURL *urlBack = [[BentoShop sharedInstance] getMenuImageURL];
    [ivBackground sd_setImageWithURL:urlBack placeholderImage:[UIImage imageNamed:@"first_background"]];
    ivBackground.clipsToBounds = YES;
    ivBackground.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:ivBackground];
    [ivBackground.layer insertSublayer:gradient atIndex:0];
    
    JGProgressHUD *loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Waiting for internet connectivity...";
    [loadingHUD showInView:self.view];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"networkError" object:nil];
    
    isConnected = NO;
}

- (void)yesConnection
{
    isConnected = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
