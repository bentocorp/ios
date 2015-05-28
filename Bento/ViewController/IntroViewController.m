//
//  IntroViewController.m
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "IntroViewController.h"

#import "UIImageView+WebCache.h"

#import "BentoShop.h"
#import "AppStrings.h"
#import "DataManager.h"
#import "JGProgressHUD.h"

@interface IntroViewController()

@property (nonatomic, assign) IBOutlet UIImageView *ivBackground;

@property (nonatomic, assign) IBOutlet UILabel *lblComment;

@property (nonatomic, assign) IBOutlet UILabel *lblNumber1;
@property (nonatomic, assign) IBOutlet UILabel *lblNumber2;
@property (nonatomic, assign) IBOutlet UILabel *lblNumber3;

@property (nonatomic, assign) IBOutlet UIImageView *ivLogo;

@property (nonatomic, assign) IBOutlet UILabel *lblItem0;
@property (nonatomic, assign) IBOutlet UILabel *lblItem1;
@property (nonatomic, assign) IBOutlet UILabel *lblItem2;
@property (nonatomic, assign) IBOutlet UILabel *lblItem3;

@property (nonatomic, assign) IBOutlet UIButton *btnGetStarted;

@end

@implementation IntroViewController
{
    JGProgressHUD *loadingHUD;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    // Gradient
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.ivBackground.bounds;
    
    // get colors for gradient
    UIColor *color1 = [DataManager getGradientColor1];
    UIColor *color2 = [DataManager getGradientColor2];
    
    // set gradient (light to darker green)
    gradient.colors = @[(id)[color1 CGColor], (id)[color2 CGColor]];
    [self.ivBackground.layer insertSublayer:gradient atIndex:0];
    
    // Asynchronously download background image URL, then set it, use placeholder if unavailable
    NSURL *urlBack = [[BentoShop sharedInstance] getMenuImageURL];
    [self.ivBackground sd_setImageWithURL:urlBack placeholderImage:[UIImage imageNamed:@"first_background"]];
    
    // Round out corners for number labels
    self.lblNumber1.layer.cornerRadius = self.lblNumber1.frame.size.width / 2;
    self.lblNumber1.clipsToBounds = YES;

    self.lblNumber2.layer.cornerRadius = self.lblNumber2.frame.size.width / 2;
    self.lblNumber2.clipsToBounds = YES;
    
    self.lblNumber3.layer.cornerRadius = self.lblNumber3.frame.size.width / 2;
    self.lblNumber3.clipsToBounds = YES;
    
    self.btnGetStarted.layer.cornerRadius = 3;
    
    // Asynchronously download bento logo, then set it, use placeholder if unavailable
    NSURL *urlLogo = [[AppStrings sharedInstance] getURL:APP_LOGO];
    [self.ivLogo sd_setImageWithURL:urlLogo placeholderImage:[UIImage imageNamed:@"logo"]];
    
    // Get prices
    NSInteger salePrice = [[AppStrings sharedInstance] getInteger:SALE_PRICE];
    NSInteger unitPrice = [[AppStrings sharedInstance] getInteger:ABOUT_PRICE];
    
    // set price string
    NSString *strPrice = @"";

    // sale price is not 0 and less than unit price
    if (salePrice != 0 && salePrice < unitPrice)
        strPrice = [NSString stringWithFormat:@"$%ld!", (long)salePrice]; // set price string as sale price
    else
        strPrice = [NSString stringWithFormat:@"$%ld!", (long)unitPrice]; //  set price string as unit price
    
    // set up string for about text
    NSString *strItem0 = [[AppStrings sharedInstance] getString:ABOUT_ITEM_0]; // "Build your Bento for only $X" ?
    strItem0 = [strItem0 stringByReplacingOccurrencesOfString:@"$X!" withString:strPrice]; // replace $X with actualy price string
    self.lblItem0. text = strItem0; // set the about label text
    
    // get instructional text and set as item label text
    self.lblItem1.text = [[AppStrings sharedInstance] getString:ABOUT_ITEM_1];
    self.lblItem2.text = [[AppStrings sharedInstance] getString:ABOUT_ITEM_2];
    self.lblItem3.text = [[AppStrings sharedInstance] getString:ABOUT_ITEM_3];
    
    // get button title text and set it to button
    [self.btnGetStarted setTitle:[[AppStrings sharedInstance] getString:ABOUT_BUTTON_TITLE] forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
}

- (void)noConnection
{
    if (loadingHUD == nil)
    {
        loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        loadingHUD.textLabel.text = @"Waiting for internet connectivity...";
        [loadingHUD showInView:self.view];
    }
}

- (void)yesConnection
{
    [loadingHUD dismiss];
    loadingHUD = nil;
}

- (IBAction)onGetStarted:(id)sender
{
    // persist a BOOL value of YES for HasLaunchedOnce
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // dismiss view
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
