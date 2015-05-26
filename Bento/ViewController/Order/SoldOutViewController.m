//
//  SoldOutViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "SoldOutViewController.h"

#import "FaqViewController.h"

#import "PreviewViewController.h"

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
@property (weak, nonatomic) IBOutlet UIButton *btnPreview;

@property (nonatomic, assign) IBOutlet UIButton *btnPolicy;
@property (nonatomic, assign) IBOutlet UIButton *btnTerms;

@property (weak, nonatomic) IBOutlet UILabel *lunchAndDinnerHoursLabel;
@property (weak, nonatomic) IBOutlet UILabel *openingHoursLabel;

@end

@implementation SoldOutViewController
{
    float currentTime;
    float lunchTime;
    float dinnerTime;
    float bufferTime;
    
    NSString *strTitle;
}

- (NSString *)getClosedText
{
    NSDate* currentDate = [NSDate date];
    
#ifdef DEBUG
    NSTimeZone* currentTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT-08:00"];
    NSTimeZone* nowTimeZone = [NSTimeZone systemTimeZone];
    
    NSInteger currentGMTOffset = [currentTimeZone secondsFromGMTForDate:currentDate];
    NSInteger nowGMTOffset = [nowTimeZone secondsFromGMTForDate:currentDate];
    
    NSTimeInterval interval = currentGMTOffset - nowGMTOffset;
    currentDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:currentDate];
#endif
    
    currentTime = [[[BentoShop sharedInstance] getCurrentTime] floatValue];
    lunchTime = [[[BentoShop sharedInstance] getLunchTime] floatValue];
    dinnerTime = [[[BentoShop sharedInstance] getDinnerTime] floatValue];
    bufferTime = [[[BentoShop sharedInstance] getBufferTime] floatValue];
    
    // 17:30 - 23:59, Closed for the night, talk about next menu
    if (currentTime >= (dinnerTime + bufferTime) && currentTime < 24) {
        return [[AppStrings sharedInstance] getString:CLOSED_TEXT_LATENIGHT];
    }

    // talk about today
    return [[AppStrings sharedInstance] getString:CLOSED_TEXT_CONTENT];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    
    self.openingHoursLabel.adjustsFontSizeToFitWidth = YES;
    self.lunchAndDinnerHoursLabel.adjustsFontSizeToFitWidth = YES;
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.ivBackground.bounds;
    
    UIColor *color1 = [DataManager getGradientColor1];
    UIColor *color2 = [DataManager getGradientColor2];
    gradient.colors = [NSArray arrayWithObjects:(id)[color1 CGColor], (id)[color2 CGColor], nil];
    [self.ivBackground.layer insertSublayer:gradient atIndex:0];
    
    NSURL *urlBack = [[BentoShop sharedInstance] getMenuImageURL];
    [self.ivBackground sd_setImageWithURL:urlBack placeholderImage:[UIImage imageNamed:@"first_background"]];
    
    NSURL *urlLogo = [[AppStrings sharedInstance] getURL:APP_LOGO];
    [self.ivTitle sd_setImageWithURL:urlLogo placeholderImage:[UIImage imageNamed:@"logo_title"]];
    
    self.lblMessageContent.adjustsFontSizeToFitWidth = YES;
    
    if (self.type == 0) // Closed
    {
        self.lblMessageTitle.text = [[AppStrings sharedInstance] getString:CLOSED_TEXT_TITLE];
        self.lblMessageContent.text = [self getClosedText];
        
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
    
    self.btnPreview.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.btnPreview.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    self.btnPreview.layer.cornerRadius = 8;
    self.btnPreview.layer.borderWidth = 1;
    self.btnPreview.layer.borderColor = [[UIColor whiteColor] CGColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setPreviewButtonText];
    
    [self onUpdatedStatus];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willChangeKeyboardFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super viewWillDisappear:animated];
}

- (void)setPreviewButtonText
{
    // set type
    if ([[BentoShop sharedInstance] isClosed])
    {
        self.type = 0;
    }
    else if ([[BentoShop sharedInstance] isSoldOut])
    {
        self.type = 1;
    }
    
    // Closed && 17:30 - 23:59 (get next)
    if (self.type == 0 && currentTime >= (dinnerTime + bufferTime) && currentTime < 24)
    {
        strTitle = [NSString stringWithFormat:@"See %@'s Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
    }
    
    // Closed &&  00:00 - 17:29 (get today, if none today, get next)
    else if (self.type == 0 && currentTime >= 0 && currentTime < (dinnerTime + bufferTime))
    {
        strTitle = [NSString stringWithFormat:@"See %@'s Menu", [[BentoShop sharedInstance] getNextMenuDateIfTodayMenuReturnsNil]];
    }
    
    // Sold out
    else
    {
        strTitle = [NSString stringWithFormat:@"See %@'s Menu", [[BentoShop sharedInstance] getMenuWeekdayString]];
    }
    
    [self.btnPreview setTitle:[strTitle uppercaseString] forState:UIControlStateNormal];
}

- (void)onUpdatedStatus
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

- (void)willShowKeyboard:(NSNotification*)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    [self moveToShowablePosition:keyboardFrameBeginRect.size.height];
}

- (void)willChangeKeyboardFrame:(NSNotification *)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    [self moveToShowablePosition:keyboardFrameBeginRect.size.height];
}

- (void)willHideKeyboard:(NSNotification *)notification
{
    [UIView animateWithDuration:0.3f animations:^{
        self.viewMain.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    }];
}

- (void) moveToShowablePosition:(float)keyboardHeight
{
    if(self.viewMain.center.y > (self.view.frame.size.height - keyboardHeight))
    {
        [UIView animateWithDuration:0.3f animations:^{
            self.viewMain.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height - keyboardHeight - 15);
        }];
    }
}

- (void)onBack
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onPrivacyPolicy:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FaqViewController *destVC = [storyboard instantiateViewControllerWithIdentifier:@"FAQID"];
    destVC.contentType = CONTENT_PRIVACY;
    [self.navigationController pushViewController:destVC animated:YES];
}

- (IBAction)onTermsAndConditions:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FaqViewController *destVC = [storyboard instantiateViewControllerWithIdentifier:@"FAQID"];
    destVC.contentType = CONTENT_TERMS;
    [self.navigationController pushViewController:destVC animated:YES];
}

- (IBAction)onHelp:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FaqViewController *destVC = [storyboard instantiateViewControllerWithIdentifier:@"FAQID"];
    destVC.contentType = CONTENT_FAQ;
    [self.navigationController pushViewController:destVC animated:YES];
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
    
    
    NSString *strRequest = [NSString stringWithFormat:@"%@/coupon/request", SERVER_URL];
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

- (IBAction)onGotoMenu:(id)sender
{
    PreviewViewController *previewViewController = [[PreviewViewController alloc] init];
    [self.navigationController pushViewController:previewViewController animated:YES];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self doSubmit];
    
    return YES;
}

@end
