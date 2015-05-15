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
#import "MyBentoViewController.h"
#import "SignInViewController.h"
#import "FaqViewController.h"
#import <MessageUI/MessageUI.h>
#import "DataManager.h"
#import "SignedInSettingsViewController.h"
#import "RegisterViewController.h"
#import "MyAlertView.h"

@interface SignedOutSettingsViewController () <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate>

@end

@implementation SignedOutSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithRed:0.914f green:0.925f blue:0.925f alpha:1.0f];
    
    /*-----------------------------------------------------------*/
    
    
    // navigation bar color
    UIView *navigationBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 65)];
    navigationBarView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navigationBarView];
    
    // title label
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 2 - 110, 20, 220, 45)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    titleLabel.textColor = [UIColor colorWithRed:0.341f green:0.376f blue:0.439f alpha:1.0f];
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
    
    MyAlertView *callAlertView = [[MyAlertView alloc] initWithTitle:nil message:@"(415) 300-1332" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitle:@"Call"];
    
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
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tel:4153001332"]];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
