//
//  NetworkErrorViewController.m
//  Bento
//
//  Created by Joseph Lau on 5/26/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "NetworkErrorViewController.h"
#import "DataManager.h"
#import "BentoShop.h"
#import "UIImageView+WebCache.h"
#import "AppStrings.h"

@interface NetworkErrorViewController ()

@end

@implementation NetworkErrorViewController
{
    UIImageView *ivBackground;
    UIImageView *ivTitle;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = ivBackground.bounds;
    
    UIColor *color1 = [DataManager getGradientColor1];
    UIColor *color2 = [DataManager getGradientColor2];
    gradient.colors = [NSArray arrayWithObjects:(id)[color1 CGColor], (id)[color2 CGColor], nil];
    [ivBackground.layer insertSublayer:gradient atIndex:0];
    
    ivBackground = [[UIImageView alloc] initWithFrame:self.view.bounds];
    NSURL *urlBack = [[BentoShop sharedInstance] getMenuImageURL];
    [ivBackground sd_setImageWithURL:urlBack placeholderImage:[UIImage imageNamed:@"first_background"]];
    [self.view addSubview:ivBackground];
    
    NSURL *urlLogo = [[AppStrings sharedInstance] getURL:APP_LOGO];
    [ivTitle sd_setImageWithURL:urlLogo placeholderImage:[UIImage imageNamed:@"logo_title"]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"networkError" object:nil];
}

- (void)yesConnection
{
    [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(timerDidEnd) userInfo:nil repeats:NO];
}

- (void)timerDidEnd
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
