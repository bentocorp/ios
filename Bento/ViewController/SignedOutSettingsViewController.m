//
//  SignedOutSettingsViewController.m
//  settings
//
//  Created by Joseph Lau on 4/23/15.
//  Copyright (c) 2015 Joseph Lau. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#import "SignedOutSettingsViewController.h"
#import "SettingsTableViewCell.h"
#import "SignInViewController.h"
#import "FaqViewController.h"
#import <MessageUI/MessageUI.h>
#import "DataManager.h"
#import "SignedInSettingsViewController.h"
#import "RegisterViewController.h"
#import "MyAlertView.h"
#import "JGProgressHUD.h"
#import "BentoShop.h"
#import "UIColor+CustomColors.h"
#import <PureLayout/PureLayout.h>
#import "Mixpanel.h"

@interface SignedOutSettingsViewController () <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate>

@end

@implementation SignedOutSettingsViewController
{
    MyAlertView *callAlertView;
    JGProgressHUD *loadingHUD;
    
    BOOL isThereConnection;
}

// AUTOLAYOUT EXAMPLE
//- (void)updateViewConstraints {
//    [self.box autoSetDimensionsToSize:CGSizeMake(30, 30)];
//    [box autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
//    [box autoAlignAxisToSuperviewAxis:ALAxisVertical];
//
//    
//    [super updateViewConstraints];
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    

    
    // initialize yes
    isThereConnection = YES;
    
    self.view.backgroundColor = [UIColor bentoBackgroundGray];
    
//    UIView *box = [[UIView alloc] initForAutoLayout];
//
//    [self.view addSubview:box];
//    [self.view setNeedsUpdateConstraints];
//    
    /*-----------------------------------------------------------*/
    
    // navigation bar color
    UIView *navigationBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 65)];
    navigationBarView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navigationBarView];
    
    // title label
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 2 - 110, 20, 220, 45)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    titleLabel.textColor = [UIColor bentoTitleGray];
    titleLabel.text = @"Settings";
    [self.view addSubview:titleLabel];
    
    // back button
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 50, 45)];
    [closeButton setImage:[UIImage imageNamed:@"nav_btn_close"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(onCloseButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    /*-----------------------------------------------------------*/
    
    // table view
    UITableView *settingsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 66, SCREEN_WIDTH, 180)];
    settingsTableView.alwaysBounceVertical = NO;
    [settingsTableView setSeparatorInset:UIEdgeInsetsMake(0, 60, 0, 0)];
    settingsTableView.delegate = self;
    settingsTableView.dataSource = self;
    [self.view addSubview:settingsTableView];
    
    // line separator under nav bar
    UIView *longLineSepartor1 = [[UIView alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, 1)];
    longLineSepartor1.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
    [self.view addSubview:longLineSepartor1];
    
    // line separator at bottom of table view
    UIView *longLineSepartor2 = [[UIView alloc] initWithFrame:CGRectMake(0, 245, SCREEN_WIDTH, 2)];
    longLineSepartor2.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
    [self.view addSubview:longLineSepartor2];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimerOnViewedScreen) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endTimerOnViewedScreen) name:@"enteringBackground" object:nil];
    
    [self startTimerOnViewedScreen];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
    
    [self endTimerOnViewedScreen];
}

#pragma mark Duration on screen
- (void)startTimerOnViewedScreen
{
    [[Mixpanel sharedInstance] timeEvent:@"Viewed Signed Out Settings Screen"];
}

- (void)endTimerOnViewedScreen
{
    [[Mixpanel sharedInstance] track:@"Viewed Signed Out Settings Screen"];
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

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SettingsTableViewCell *settingsTableViewCell = (SettingsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (settingsTableViewCell == nil) {
        settingsTableViewCell = [[SettingsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    switch (indexPath.row) {
        case 0:
            settingsTableViewCell.settingsLabel.text = @"Sign in";
            settingsTableViewCell.iconImageView.image = [UIImage imageNamed:@"icon-square-user"];
            break;
        case 1:
            settingsTableViewCell.settingsLabel.text = @"FAQ";
            settingsTableViewCell.iconImageView.image = [UIImage imageNamed:@"icon-square-help"];
            break;
        case 2:
            settingsTableViewCell.settingsLabel.text = @"Email Support";
            settingsTableViewCell.iconImageView.image = [UIImage imageNamed:@"icon-square-email"];

            break;
        case 3:
            settingsTableViewCell.settingsLabel.text = @"Phone Support";
            settingsTableViewCell.iconImageView.image = [UIImage imageNamed:@"icon-square-phone"];

            break;
    }
    
    return settingsTableViewCell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove table cell highlight
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    callAlertView = [[MyAlertView alloc] initWithTitle:nil message:@"(415) 300-1332" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitle:@"Call"];
    
    MFMailComposeViewController *mailComposeViewController;
    NSArray *toRecipentsArray;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *destVC;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    switch (indexPath.row) {
        case 0:
            
            // go to sign in
            [defaults setObject:@"" forKey:@"cameFromWhichVC"];
            [defaults synchronize];
            
            destVC = [storyboard instantiateViewControllerWithIdentifier:@"SignInID"];
            [self.navigationController pushViewController:destVC animated:YES];
            
            break;
            
        case 1:
            
            // go to faq
            destVC = [storyboard instantiateViewControllerWithIdentifier:@"FAQID"];
            [self.navigationController pushViewController:destVC animated:YES];
            
            break;
            
        case 2:
            
            // To Email Address
            toRecipentsArray = [NSArray arrayWithObject:@"help@bentonow.com"];
            
            mailComposeViewController = [[MFMailComposeViewController alloc] init];
            mailComposeViewController.mailComposeDelegate = self;
            [mailComposeViewController setToRecipients:toRecipentsArray];
            
            // Present mail view controller on screen
            if ([MFMailComposeViewController canSendMail])
                [self presentViewController:mailComposeViewController animated:YES completion:NULL];
            
            break;
            
        case 3:
            
            // show call alert
            callAlertView.tag = 1;
            [callAlertView showInView:self.view];
            callAlertView = nil;
            break;
    }
}

-(void)onCloseButton
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Email delegate method
- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)alertView:(MyAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tel:1-415-300-1332"]];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
