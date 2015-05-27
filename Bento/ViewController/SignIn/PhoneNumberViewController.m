//
//  PhoneNumberViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "PhoneNumberViewController.h"

#import "FaqViewController.h"

#import "MyAlertView.h"
#import "JGProgressHUD.h"
#import "SHSPhoneTextField.h"

#import "AppStrings.h"
#import "WebManager.h"
#import "DataManager.h"
#import "FacebookManager.h"

@interface PhoneNumberViewController ()

@property (nonatomic, assign) IBOutlet UILabel *lblTitle;

@property (nonatomic, assign) IBOutlet UIView *viewError;
@property (nonatomic, assign) IBOutlet UILabel *lblError;

@property (nonatomic, assign) IBOutlet UILabel *lblDescription;

@property (nonatomic, assign) IBOutlet UIImageView *ivPhoneNumber;
@property (nonatomic, assign) IBOutlet SHSPhoneTextField *txtPhoneNumber;

@property (nonatomic, assign) IBOutlet UIButton *btnDone;

@property (nonatomic, assign) IBOutlet UIButton *btnPolicy;
@property (nonatomic, assign) IBOutlet UIButton *btnTerms;

@property (weak, nonatomic) IBOutlet UIView *viewPhoneNumber;

@end

@implementation PhoneNumberViewController

- (void)onTextChanged:(UITextField *)textField
{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.btnDone.layer.cornerRadius = 3;
    self.btnDone.clipsToBounds = YES;
    
    self.lblTitle.text = [[AppStrings sharedInstance] getString:PHNUMBER_TITLE];
    self.lblDescription.text = [[AppStrings sharedInstance] getString:PHNUMBER_DESC];
    
    [self.btnDone setTitle:[[AppStrings sharedInstance] getString:PHNUMBER_BUTTON_DONE] forState:UIControlStateNormal];
    [self.btnPolicy setTitle:[[AppStrings sharedInstance] getString:PHNUMBER_LINK_POLICY] forState:UIControlStateNormal];
    [self.btnTerms setTitle:[[AppStrings sharedInstance] getString:PHNUMBER_LINK_TERMS] forState:UIControlStateNormal];

    [self showErrorMessage:nil code:ERROR_NONE];
    
    [self.txtPhoneNumber setTextDidChangeBlock:^(UITextField *textField) {
        [self updateUI];
    }];
    
    [self.txtPhoneNumber.formatter setDefaultOutputPattern:@"(###) ### - ####"];
    self.txtPhoneNumber.formatter.prefix = @"+1 ";
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
    
    if ([segue.identifier isEqualToString:@"Faq"])
    {
        FaqViewController *vc = segue.destinationViewController;
        vc.contentType = [sender intValue];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willChangeKeyboardFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(popBack) name:@"networkError" object:nil];
    
    [self updateUI];
}

- (void)popBack
{
    [(UINavigationController *)self.presentingViewController popToRootViewControllerAnimated:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super viewWillDisappear:animated];
}

- (void) willShowKeyboard:(NSNotification*)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    [self repositionPhoneView:keyboardFrameBeginRect.size.height];
}

- (void) willChangeKeyboardFrame:(NSNotification *)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    [self repositionPhoneView:keyboardFrameBeginRect.size.height];
}

- (void) willHideKeyboard:(NSNotification *)notification
{
    [UIView animateWithDuration:0.3f animations:^{
        
        self.viewPhoneNumber.center = CGPointMake(self.viewPhoneNumber.center.x, self.view.frame.size.height / 2);
        
    } completion:^(BOOL finished) {
        
    }];
}

- (void) repositionPhoneView:(float) keyboardHeight
{
    [UIView animateWithDuration:0.3f animations:^{
        
        float newCenterY = self.view.frame.size.height - keyboardHeight - self.viewPhoneNumber.frame.size.height / 2;
        
        if(newCenterY < self.viewPhoneNumber.center.y)
        {
            self.viewPhoneNumber.center = CGPointMake(self.viewPhoneNumber.center.x, newCenterY);
        }
        
    } completion:^(BOOL finished) {
        
    }];
}

- (void)showErrorMessage:(NSString *)errorMsg code:(int)errorCode
{
    if (errorMsg == nil || errorMsg.length == 0)
    {
        self.viewError.hidden = YES;
    }
    else
    {
        self.viewError.hidden = NO;
        self.lblError.text = errorMsg;
    }
    
    UIColor *errorColor = [UIColor colorWithRed:233.0f / 255.0f green:114.0f / 255.0f blue:2.0f / 255.0f alpha:1.0f];
    UIColor *correctColor = [UIColor colorWithRed:109.0f / 255.0f green:117.0f / 255.0f blue:131.0f / 255.0f alpha:1.0f];
    
    switch (errorCode) {
        case ERROR_NONE:
        {
            self.viewError.hidden = YES;
            
            self.ivPhoneNumber.image = [UIImage imageNamed:@"register_icon_phone"];
            self.txtPhoneNumber.textColor = correctColor;
        }
            break;
            
        case ERROR_PHONENUMBER:
        {
            self.viewError.hidden = NO;
            
            self.ivPhoneNumber.image = [UIImage imageNamed:@"register_icon_phone_err"];
            self.txtPhoneNumber.textColor = errorColor;
        }
            break;
            
        default:
            break;
    }
}

- (IBAction)onBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onPrivacyPolicy:(id)sender
{
    [self performSegueWithIdentifier:@"Faq" sender:[NSNumber numberWithInt:CONTENT_PRIVACY]];
}

- (IBAction)onTermsAndConditions:(id)sender
{
    [self performSegueWithIdentifier:@"Faq" sender:[NSNumber numberWithInt:CONTENT_TERMS]];
}

- (void)processRegister
{
    NSString *strMailAddr = [self.userInfo valueForKey:@"email"];
    NSString *strFirstName = [self.userInfo valueForKey:@"first_name"];
    NSString *strLastName = [self.userInfo valueForKey:@"last_name"];
    NSString *strFBID = [self.userInfo valueForKey:@"id"];
    NSString *strUserName = [self.userInfo valueForKey:@"name"];
    NSString *strGender = [self.userInfo valueForKey:@"gender"];
    NSString *strPhotoURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", strFBID];
    NSString *strPhoneNumber = self.txtPhoneNumber.text;
    NSString *strAccessToken = [[[FBSession activeSession] accessTokenData] accessToken];
    
    NSString *strAgeRange = @"";
    NSDictionary *ageRangeDict = [[FacebookManager sharedInstance].userDetails objectForKey:@"age_range"];
    if (ageRangeDict != nil)
    {
        if ([ageRangeDict objectForKey:@"min"] != nil && [ageRangeDict objectForKey:@"max"] != nil)
            strAgeRange = [NSString stringWithFormat:@"%@-%@", [ageRangeDict objectForKey:@"min"], [ageRangeDict objectForKey:@"max"]];
        else if ([ageRangeDict objectForKey:@"min"] != nil)
            strAgeRange = [NSString stringWithFormat:@"%@+", [ageRangeDict objectForKey:@"min"]];
        else if ([ageRangeDict objectForKey:@"max"] != nil)
            strAgeRange = [NSString stringWithFormat:@"-%@", [ageRangeDict objectForKey:@"max"]];
        else
            strAgeRange = @"";
    }
    
    if (strGender == nil)
        strGender = @"";
    
    NSDictionary* request = @{
                              @"firstname" : strFirstName,
                              @"lastname" : strLastName,
                              @"email" : strMailAddr,
                              @"phone" : strPhoneNumber,
                              @"fb_id" : strFBID,
                              @"fb_profile_pic" : strPhotoURL,
                              @"fb_gender" : strGender,
                              @"fb_age_range" : strAgeRange,
                              @"fb_token" : strAccessToken,
                              };
    
    NSDictionary *dicRequest = @{@"data" : [request jsonEncodedKeyValueString]};
    WebManager *webManager = [[WebManager alloc] init];
    
    JGProgressHUD *loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Registering...";
    [loadingHUD showInView:self.view];
    
    NSString *strRequest = [NSString stringWithFormat:@"%@/user/fbsignup", SERVER_URL];
    [webManager AsyncProcess:strRequest method:POST parameters:dicRequest success:^(MKNetworkOperation *networkOperation) {
        [loadingHUD dismiss];
        
        NSDictionary *response = networkOperation.responseJSON;
        [[DataManager shareDataManager] setUserInfo:response];
        
        NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
        NSString *strRequest = [NSString stringWithFormat:@"%@/user/fblogin", SERVER_URL];
        [pref setObject:strRequest forKey:@"apiName"];
        
        NSDictionary *fbloginRequest = @{
                                         @"email" : strMailAddr,
                                         @"fb_id" : strFBID,
                                         @"fb_token" : strAccessToken,
                                       };
        NSDictionary *saveRequest = @{@"data" : [fbloginRequest jsonEncodedKeyValueString]};
        [pref setObject:saveRequest forKey:@"loginRequest"];
        [pref synchronize];
        
        [self showErrorMessage:nil code:ERROR_NONE];
        [self gotoDeliveryLocationScreen];
        
    } failure:^(MKNetworkOperation *errorOp, NSError *error) {
        
        [loadingHUD dismiss];
        
        NSString *strMessage = [[DataManager shareDataManager] getErrorMessage:errorOp.responseJSON];
        if (strMessage == nil)
            strMessage = error.localizedDescription;
        
        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:strMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
        [alertView showInView:self.view];
        alertView = nil;
        return;
        
    } isJSON:NO];
}

- (IBAction)onDone:(id)sender
{
    NSString *strPhoneNumber = self.txtPhoneNumber.text;
    if (strPhoneNumber.length == 0)
    {
        [self showErrorMessage:@"Please enter a phone number." code:ERROR_PHONENUMBER];
        return;
    }
    
    if (![DataManager isValidPhoneNumber:strPhoneNumber])
    {
        [self showErrorMessage:@"Please enter a valid phone number." code:ERROR_PHONENUMBER];
        return;
    }
    
    [self processRegister];
}

- (void)updateUI
{
    NSString *strPhoneNumber = self.txtPhoneNumber.text;
    if (strPhoneNumber.length > 0 && [DataManager isValidPhoneNumber:strPhoneNumber])
    {
        self.btnDone.enabled = YES;
        [self.btnDone setBackgroundColor:[UIColor colorWithRed:135.0f / 255.0f green:178.0f / 255.0f blue:96.0f / 255.0f alpha:1.0f]];
    }
    else
    {
        self.btnDone.enabled = NO;
        [self.btnDone setBackgroundColor:[UIColor colorWithRed:122.0f / 255.0f green:133.0f / 255.0f blue:146.0f / 255.0f alpha:1.0f]];
    }
}

- (void) gotoDeliveryLocationScreen
{
    [self dissmodal];
}

- (void) dissmodal
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
