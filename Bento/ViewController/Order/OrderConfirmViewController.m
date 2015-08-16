//
//  OrderConfirmViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#import "OrderConfirmViewController.h"

#import "CustomBentoViewController.h"
#import "FixedBentoViewController.h"

#import "UIImageView+WebCache.h"

#import "AppStrings.h"
#import "BentoShop.h"
#import "Mixpanel.h"

#import "JGProgressHUD.h"

@interface OrderConfirmViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *ivTitle;

@property (nonatomic, weak) IBOutlet UIImageView *ivCompleted;

@property (nonatomic, weak) IBOutlet UILabel *lblCompletedTitle;

@property (nonatomic, weak) IBOutlet UILabel *lblCompletedText;

@property (nonatomic, weak) IBOutlet UIButton *btnQuestion;

@property (nonatomic, weak) IBOutlet UIButton *btnBuild;

- (IBAction)onHelp:(id)sender;

@end

@implementation OrderConfirmViewController
{
    JGProgressHUD *loadingHUD;
    
    UILabel *lblPushRequest;
    UILabel *lblPushComment;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURL *urlLogo = [[AppStrings sharedInstance] getURL:APP_LOGO];
    [self.ivTitle sd_setImageWithURL:urlLogo placeholderImage:[UIImage imageNamed:@"logo_title"]];
    
    NSURL *urlCompleted = [[AppStrings sharedInstance] getURL:COMPLETED_IMAGE_CAR];
    [self.ivCompleted sd_setImageWithURL:urlCompleted placeholderImage:[UIImage imageNamed:@"orderconfirm_image_car"]];
    
    self.lblCompletedTitle.text = [[AppStrings sharedInstance] getString:COMPLETED_TITLE];
    self.lblCompletedText.text = [[AppStrings sharedInstance] getString:COMPLETED_TEXT];
    [self.btnQuestion setTitle:[[AppStrings sharedInstance] getString:COMPLETED_LINK_QUESTION] forState:UIControlStateNormal];
    [self.btnBuild setTitle:[[AppStrings sharedInstance] getString:COMPLETED_BUTTON_COMPLETE] forState:UIControlStateNormal];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"Push Requested"] == nil)
    {
        self.ivCompleted.alpha = 0;
        self.lblCompletedTitle.alpha = 0;
        self.lblCompletedText.alpha = 0;
        self.btnQuestion.alpha = 0;
        
        // Push Notifications Request
        CGSize result = [[UIScreen mainScreen] bounds].size;
        if(result.height == 480)
        {
            // iphone 4
            lblPushRequest = [[UILabel alloc] initWithFrame:CGRectMake(40, 120, self.view.bounds.size.width - 80, 44)];
            lblPushComment = [[UILabel alloc] initWithFrame:CGRectMake(20, 330, self.view.bounds.size.width - 40, 250)];
        }
        
        else if(result.height == 568)
        {
            // iphone 5
            lblPushRequest = [[UILabel alloc] initWithFrame:CGRectMake(40, 120, self.view.bounds.size.width - 80, 44)];
            lblPushComment = [[UILabel alloc] initWithFrame:CGRectMake(20, 330, self.view.bounds.size.width - 40, 250)];
        }
        
        else if(result.height == 667)
        {
            // iphone 6
            lblPushRequest = [[UILabel alloc] initWithFrame:CGRectMake(40, 140, self.view.bounds.size.width - 80, 44)];
            lblPushComment = [[UILabel alloc] initWithFrame:CGRectMake(40, 390, self.view.bounds.size.width - 80, 250)];
        }
        
        else if(result.height == 736)
        {
            // iphone 6+
            lblPushRequest = [[UILabel alloc] initWithFrame:CGRectMake(40, 200, self.view.bounds.size.width - 80, 44)];
            lblPushComment = [[UILabel alloc] initWithFrame:CGRectMake(40, 400, self.view.bounds.size.width - 80, 250)];
        }
        
        // title
        lblPushRequest.textAlignment = NSTextAlignmentCenter;
        if (self.view.bounds.size.width == 320)
            lblPushRequest.font = [UIFont fontWithName:@"OpenSans-Semibold" size:17];
        else if (self.view.bounds.size.width == 375)
            lblPushRequest.font = [UIFont fontWithName:@"OpenSans-Semibold" size:20];
        else
            lblPushRequest.font = [UIFont fontWithName:@"OpenSans-Semibold" size:24];
        lblPushRequest.textColor = [UIColor darkGrayColor];
        lblPushRequest.text = @"Don't miss your order!";
        [self.view addSubview:lblPushRequest];
        
        // comment
        lblPushComment.adjustsFontSizeToFitWidth = YES;
        if (self.view.bounds.size.width == 320)
            lblPushComment.font = [UIFont fontWithName:@"OpenSans-Semibold" size:17];
        else if (self.view.bounds.size.width == 375)
            lblPushComment.font = [UIFont fontWithName:@"OpenSans-Semibold" size:20];
        else
            lblPushComment.font = [UIFont fontWithName:@"OpenSans-Semibold" size:24];
        lblPushComment.numberOfLines = 0;
        lblPushComment.textAlignment = NSTextAlignmentCenter;
        lblPushComment.textColor = [UIColor darkGrayColor];
        lblPushComment.text = @"Allow push notifications to get timely updates & information about your order status!";
        [self.view addSubview:lblPushComment];
        
        [self requestPush];
    }
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

- (void)checkCurrentMode
{
    if ([[BentoShop sharedInstance] didModeOrDateChange])
    {
        [(UINavigationController *)self.presentingViewController popToRootViewControllerAnimated:NO];
        [self dismissViewControllerAnimated:YES completion:nil];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated
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

#pragma mark Push Notifications

- (void)requestPush
{
    //Request for Push Notifications
    // iOS 8 and up
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
    {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    
    // iOS 7 and below
    else
    {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIRemoteNotificationTypeNewsstandContentAvailability| UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel.people addPushDeviceToken:deviceToken];
    
    [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"Push Requested"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSLog(@"%@", deviceToken);
}

@end
