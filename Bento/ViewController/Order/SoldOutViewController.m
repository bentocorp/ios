//
//  SoldOutViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "SoldOutViewController.h"

#import "FaqViewController.h"

#import "MyAlertView.h"

#import "UIImageView+WebCache.h"

#import "JGProgressHUD.h"

#import "BentoShop.h"
#import "AppStrings.h"
#import "WebManager.h"
#import "DataManager.h"

@interface SoldOutViewController ()

@property (nonatomic, assign) IBOutlet UIView *viewMain;

@property (nonatomic, assign) IBOutlet UIImageView *ivBackground;

@property (nonatomic, assign) IBOutlet UIImageView *ivTitle;

@property (nonatomic, assign) IBOutlet UILabel *lblMessageTitle;
@property (nonatomic, assign) IBOutlet UILabel *lblMessageContent;

@property (nonatomic, assign) IBOutlet UITextField *txtEmail;

@property (nonatomic, assign) IBOutlet UIButton *btnSend;

@property (nonatomic, assign) IBOutlet UIButton *btnPolicy;
@property (nonatomic, assign) IBOutlet UIButton *btnTerms;

@end

@implementation SoldOutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.ivBackground.bounds;
    
    UIColor *color1 = [DataManager getGradientColor1];
    UIColor *color2 = [DataManager getGradientColor2];
    gradient.colors = [NSArray arrayWithObjects:(id)[color1 CGColor], (id)[color2 CGColor], nil];
    [self.ivBackground.layer insertSublayer:gradient atIndex:0];
    
    NSURL *urlBack = [[AppStrings sharedInstance] getURL:APP_BACKGND];
    [self.ivBackground sd_setImageWithURL:urlBack placeholderImage:[UIImage imageNamed:@"first_background"]];
    
    NSURL *urlLogo = [[AppStrings sharedInstance] getURL:APP_LOGO];
    [self.ivTitle sd_setImageWithURL:urlLogo placeholderImage:[UIImage imageNamed:@"logo_title"]];
    
    if (self.type == 0) // Closed
    {
        self.lblMessageTitle.text = [[AppStrings sharedInstance] getString:CLOSED_TEXT_TITLE];
        self.lblMessageContent.text = [[AppStrings sharedInstance] getString:CLOSED_TEXT_CONTENT];
        
        self.txtEmail.placeholder = [[AppStrings sharedInstance] getString:CLOSED_PLACEHOLDER_EMAIL];
        [self.btnSend setTitle:[[AppStrings sharedInstance] getString:CLOSED_BUTTON_RECEIVE_COUPON] forState:UIControlStateNormal];
        [self.btnPolicy setTitle:[[AppStrings sharedInstance] getString:CLOSED_LINK_POLICY] forState:UIControlStateNormal];
        [self.btnTerms setTitle:[[AppStrings sharedInstance] getString:CLOSED_LINK_TERMS] forState:UIControlStateNormal];
    }
    else if (self.type == 1) // Sold Out
    {
        self.lblMessageTitle.text = [[AppStrings sharedInstance] getString:SOLDOUT_TEXT_TITLE];
        self.lblMessageContent.text = [[AppStrings sharedInstance] getString:SOLDOUT_TEXT_CONTENT];
        
        self.txtEmail.placeholder = [[AppStrings sharedInstance] getString:SOLDOUT_PLACEHOLDER_EMAIL];
        [self.btnSend setTitle:[[AppStrings sharedInstance] getString:SOLDOUT_BUTTON_RECEIVE_COUPON] forState:UIControlStateNormal];
        [self.btnPolicy setTitle:[[AppStrings sharedInstance] getString:SOLDOUT_LINK_POLICY] forState:UIControlStateNormal];
        [self.btnTerms setTitle:[[AppStrings sharedInstance] getString:SOLDOUT_LINK_TERMS] forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"Terms"])
    {
        FaqViewController *vc = segue.destinationViewController;
        vc.contentType = [sender intValue];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) onUpdatedStatus
{
    if (self.type == 0) // Closed
    {
        if (![[BentoShop sharedInstance] isClosed])
        {
            [self performSelectorOnMainThread:@selector(onBack) withObject:nil waitUntilDone:NO];
        }
            //[self.navigationController popViewControllerAnimated:YES];
    }
    else if (self.type == 1) // Sold Out
    {
        if (![[BentoShop sharedInstance] isSoldOut])
        {
            [self performSelectorOnMainThread:@selector(onBack) withObject:nil waitUntilDone:NO];
        }
            //[self.navigationController popViewControllerAnimated:YES];
    }
}

- (void) onBack
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onPrivacyPolicy:(id)sender
{
    [self performSegueWithIdentifier:@"Faq" sender:[NSNumber numberWithInt:CONTENT_PRIVACY]];
}

- (IBAction)onTermsAndConditions:(id)sender
{
    [self performSegueWithIdentifier:@"Faq" sender:[NSNumber numberWithInt:CONTENT_TERMS]];
}

- (IBAction)onHelp:(id)sender
{
    [self performSegueWithIdentifier:@"Faq" sender:[NSNumber numberWithInt:CONTENT_FAQ]];
}

- (void) showConfirmMessage
{
    NSString *strMessage = @"";
    NSString *strConfirmButton = @"";
    
    if (self.type == 0) // Closed
    {
        strMessage = [[AppStrings sharedInstance] getString:ALERT_CC_TEXT];
        strConfirmButton = [[AppStrings sharedInstance] getString:ALERT_CC_BUTTON_OK];
    }
    else if (self.type == 1) // Sold Out
    {
        strMessage = [[AppStrings sharedInstance] getString:ALERT_SOC_TEXT];
        strConfirmButton = [[AppStrings sharedInstance] getString:ALERT_SOC_BUTTON_OK];
    }
    
    MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:strMessage delegate:nil cancelButtonTitle:strConfirmButton otherButtonTitle:nil];
    
    [alertView showInView:self.view];
    alertView = nil;
}

- (void)doSubmit
{
    [self.txtEmail resignFirstResponder];
    
    NSString *strEmail = self.txtEmail.text;
    if (![DataManager isValidMailAddress:strEmail])
    {
        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:@"Please input a valid email address." delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
        
        [alertView showInView:self.view];
        alertView = nil;
        return;
    }
    
    NSString *strReason = @"";
    if (self.type == 0)
        strReason = @"closed";
    else if (self.type == 1)
        strReason = @"sold out";
    
    NSString *strToken = [[DataManager shareDataManager] getAPIToken];
    NSDictionary* postInfo = nil;
    if (strToken != nil && strToken.length > 0)
    {
        postInfo = @{
                     @"email" : strEmail,
                     @"reason" : strReason,
                     @"api_token" : strToken,
                     };
    }
    else
    {
        postInfo = @{
                     @"email" : strEmail,
                     @"reason" : strReason,
                     };
    }
    
    NSDictionary *dicRequest = @{@"data" : [postInfo jsonEncodedKeyValueString]};
    WebManager *webManager = [[WebManager alloc] init];
    
    JGProgressHUD *loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Sending...";
    [loadingHUD showInView:self.view];
    
    
    NSString *strRequest = @"/coupon/request";
    if ([[DataManager shareDataManager] getUserInfo] != nil)
        strRequest = [NSString stringWithFormat:@"%@?api_token=%@", strRequest, [[DataManager shareDataManager] getAPIToken]];
    
    [webManager AsyncProcess:strRequest method:POST parameters:dicRequest success:^(MKNetworkOperation *networkOperation) {
        [loadingHUD dismiss];
        
        [self showConfirmMessage];
        
    } failure:^(MKNetworkOperation *errorOp, NSError *error) {
        [loadingHUD dismiss];
        
        NSString *strMessage = [[DataManager shareDataManager] getErrorMessage:errorOp.responseJSON];
        if (strMessage == nil)
            strMessage = error.localizedDescription;
        
        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:strMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
        
        [alertView showInView:self.view];
        alertView = nil;
        
    } isJSON:NO];
}

- (IBAction)onSendBentoCoupon:(id)sender
{
    [self doSubmit];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self doSubmit];
    
    return YES;
}

@end
