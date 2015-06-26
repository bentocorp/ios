//
//  OrderConfirmViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "OrderConfirmViewController.h"

#import "CustomBentoViewController.h"
#import "FixedBentoViewController.h"

#import "UIImageView+WebCache.h"

#import "AppStrings.h"
#import "BentoShop.h"

#import "JGProgressHUD.h"

@interface OrderConfirmViewController ()

@property (nonatomic, assign) IBOutlet UIImageView *ivTitle;

@property (nonatomic, assign) IBOutlet UIImageView *ivCompleted;

@property (nonatomic, assign) IBOutlet UILabel *lblCompletedTitle;

@property (nonatomic, assign) IBOutlet UILabel *lblCompletedText;

@property (nonatomic, assign) IBOutlet UIButton *btnQuestion;

@property (nonatomic, assign) IBOutlet UIButton *btnBuild;

- (IBAction)onHelp:(id)sender;

@end

@implementation OrderConfirmViewController
{
    JGProgressHUD *loadingHUD;
    NSString *originalDateString;
    NSString *newDateString;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSURL *urlLogo = [[AppStrings sharedInstance] getURL:APP_LOGO];
    [self.ivTitle sd_setImageWithURL:urlLogo placeholderImage:[UIImage imageNamed:@"logo_title"]];
    
    NSURL *urlCompleted = [[AppStrings sharedInstance] getURL:COMPLETED_IMAGE_CAR];
    [self.ivCompleted sd_setImageWithURL:urlCompleted placeholderImage:[UIImage imageNamed:@"orderconfirm_image_car"]];
    
    self.lblCompletedTitle.text = [[AppStrings sharedInstance] getString:COMPLETED_TITLE];
    self.lblCompletedText.text = [[AppStrings sharedInstance] getString:COMPLETED_TEXT];
    [self.btnQuestion setTitle:[[AppStrings sharedInstance] getString:COMPLETED_LINK_QUESTION] forState:UIControlStateNormal];
    [self.btnBuild setTitle:[[AppStrings sharedInstance] getString:COMPLETED_BUTTON_COMPLETE] forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCurrentMode) name:@"enteredForeground" object:nil];
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

//- (void)preloadCheckCurrentMode
//{
//    // so date string can refresh first
//    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkCurrentMode) userInfo:nil repeats:NO];
//}

- (void)checkCurrentMode
{
    NSString *originalMenuType = [[NSUserDefaults standardUserDefaults] objectForKey:@"originalMenuType"];
    NSString *currentMenuType = [[BentoShop sharedInstance] getMenuType];
    
    // if menu type changed, reset the app
    if (![originalMenuType isEqualToString:currentMenuType])
    {
        // reset originalMenuType with currentMenuType
        [[NSUserDefaults standardUserDefaults] setObject:currentMenuType forKey:@"originalMenuType"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[BentoShop sharedInstance] resetBentoArray];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void) viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
}

- (IBAction)onAnothorBento:(id)sender
{
    [self gotoAddAnotherBentoScreen];
}

- (void)gotoAddAnotherBentoScreen
{
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    for (UIViewController *vc in viewControllers) {
        
        if ([vc isKindOfClass:[CustomBentoViewController class]] || [vc isKindOfClass:[FixedBentoViewController class]])
        {
            [[BentoShop sharedInstance] addNewBento];
            [self.navigationController popToViewController:vc animated:YES];
            
            return;
        }
    }
}

- (IBAction)onHelp:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *destVC = [storyboard instantiateViewControllerWithIdentifier:@"FAQID"];
    [self.navigationController pushViewController:destVC animated:YES];
}

@end
