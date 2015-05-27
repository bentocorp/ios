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

@interface NetworkErrorViewController ()

@end

@implementation NetworkErrorViewController
{
    UIImageView *ivBackground;
    UIAlertView *alert;
    BentoShop *globalShop;
    BOOL isConnected;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    globalShop = [BentoShop sharedInstance];
    
    UIColor *color1 = [DataManager getGradientColor1];
    UIColor *color2 = [DataManager getGradientColor2];
    
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
    
    
     alert = [[UIAlertView alloc] initWithTitle:@"No Network Connection"
                                                        message:@"Please connect to a WIFI or cellular network."
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Try again", nil];
    
    [alert show];
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
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (isConnected)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        [self viewDidLoad];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
