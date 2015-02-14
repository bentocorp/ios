//
//  RegisterViewController.m
//  Bento
//
//  Created by hanjinghe on 1/7/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "RegisterViewController.h"

#import "FaqViewController.h"
#import "PhoneNumberViewController.h"
#import "SignInViewController.h"

#import "MyAlertView.h"

#import "JGProgressHUD.h"
#import "SHSPhoneTextField.h"

#import "AppStrings.h"
#import "WebManager.h"
#import "DataManager.h"
#import "FacebookManager.h"

@interface RegisterViewController () <FBManagerDelegate>
{
    UITextField *_activeField;
}

@property (nonatomic, assign) IBOutlet UILabel *lblTitle;

@property (nonatomic, assign) IBOutlet UIScrollView *svMain;

@property (nonatomic, assign) IBOutlet UIView *viewError;
@property (nonatomic, assign) IBOutlet UILabel *lblError;

@property (nonatomic, assign) IBOutlet UIView *viewRegisterWithFacebook;

@property (nonatomic, assign) IBOutlet UIButton *btnRegister;

@property (nonatomic, assign) IBOutlet UITextField *txtYourname;
@property (nonatomic, assign) IBOutlet UITextField *txtEmail;
@property (nonatomic, assign) IBOutlet SHSPhoneTextField *txtPhoneNumber;
@property (nonatomic, assign) IBOutlet UITextField *txtPassword;

@property (nonatomic, assign) IBOutlet UIImageView *ivYourname;
@property (nonatomic, assign) IBOutlet UIImageView *ivEmail;
@property (nonatomic, assign) IBOutlet UIImageView *ivPhoneNumber;
@property (nonatomic, assign) IBOutlet UIImageView *ivPassword;

@property (nonatomic, assign) IBOutlet UIButton *btnPolicy;
@property (nonatomic, assign) IBOutlet UIButton *btnTerms;

@property (weak, nonatomic) IBOutlet UIButton *btnSignUp;

@end

@implementation RegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.lblTitle.text = [[AppStrings sharedInstance] getString:SIGNUP_TITLE];
    [self.btnRegister setTitle:[[AppStrings sharedInstance] getString:SIGNUP_BUTTON_SIGNUP] forState:UIControlStateNormal];
    [self.btnPolicy setTitle:[[AppStrings sharedInstance] getString:SIGNUP_LINK_POLICY] forState:UIControlStateNormal];
    [self.btnTerms setTitle:[[AppStrings sharedInstance] getString:SIGNUP_LINK_TERMS] forState:UIControlStateNormal];
    
    self.viewRegisterWithFacebook.layer.cornerRadius = 3;
    self.viewRegisterWithFacebook.clipsToBounds = YES;
    
    self.btnRegister.layer.cornerRadius = 3;
    self.btnRegister.clipsToBounds = YES;
    
    self.svMain.contentSize = CGSizeMake(self.svMain.frame.size.width, 504);
    
    [self.txtPhoneNumber setTextDidChangeBlock:^(UITextField *textField) {
        [self updateUI];
    }];
    
    [self.txtPhoneNumber.formatter setDefaultOutputPattern:@"(###) ### - ####"];
    
    // Facebook
    [[FacebookManager sharedInstance] setDelegate:self];
    
    _activeField = nil;
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
    else if ([segue.identifier isEqualToString:@"PhoneNumber"])
    {
        PhoneNumberViewController *vcPhoneNumber = segue.destinationViewController;
        vcPhoneNumber.userInfo = sender;
    }
    else if([segue.identifier isEqualToString:@"SignIn"])
    {
        SignInViewController *vcSignIn = segue.destinationViewController;
        
        if(sender != nil)
        {
            vcSignIn.txtEmail.text = sender;
        }
        else
        {
            vcSignIn.txtEmail.text = @"";
        }
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willChangeKeyboardFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];

    [self showErrorWithString:nil code:ERROR_NONE];
    
    [self updateUI];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) willShowKeyboard:(NSNotification*)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    [self collapseScrollView:keyboardFrameBeginRect.size.height];
}

- (void) willChangeKeyboardFrame:(NSNotification *)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    [self collapseScrollView:keyboardFrameBeginRect.size.height];
}

- (void) willHideKeyboard:(NSNotification *)notification
{
    [self expandScrollView];
}

- (void)showSignUpButton
{
    if (self.svMain.frame.size.height < self.btnRegister.frame.origin.y + self.btnRegister.frame.size.height - _activeField.frame.origin.y)
        return;
    
    BOOL isShowingButton = NO;
    CGFloat bottomOfButton = self.btnRegister.frame.origin.y + self.btnRegister.frame.size.height;
    if (bottomOfButton < self.svMain.contentOffset.y + self.svMain.frame.size.height)
        isShowingButton = YES;
    
    if (isShowingButton)
        return;
    
    self.svMain.contentOffset = CGPointMake(self.svMain.contentOffset.x,
                                            bottomOfButton + 20 - self.svMain.frame.size.height);
}

- (void) collapseScrollView:(float)keyboardHeight
{
    self.svMain.frame = CGRectMake(self.svMain.frame.origin.x, self.svMain.frame.origin.y, self.svMain.frame.size.width, self.view.frame.size.height - self.svMain.frame.origin.y - keyboardHeight);

    [self showSignUpButton];
}

- (void) expandScrollView
{
    self.svMain.frame = CGRectMake(self.svMain.frame.origin.x, self.svMain.frame.origin.y, self.svMain.frame.size.width, self.view.frame.size.height - self.svMain.frame.origin.y);
}

- (IBAction)onBack:(id)sender
{
    [self dissmodal];
}

- (void) dissmodal
{
    [self closeKeyboard];
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)reqFacebookUserInfo
{
    JGProgressHUD *loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Logging in...";
    [loadingHUD showInView:self.view];
    
    [[FacebookManager sharedInstance] loadUserDetailsWithCompletionHandler:^(NSDictionary<FBGraphUser> *user, NSError *error)
     {
         if (error == nil)
         {
             NSString *strAccessToken = [[[FBSession activeSession] accessTokenData] accessToken];
             
             NSString *strMailAddr = [user valueForKey:@"email"];
             NSString *strFBID = [user valueForKey:@"id"];
             
             NSDictionary* loginInfo = @{
                                         @"email" : strMailAddr,
                                         @"fb_id" : strFBID,
                                         @"fb_token" : strAccessToken,
                                         };
             
             NSDictionary *dicRequest = @{@"data" : [loginInfo jsonEncodedKeyValueString]};
             WebManager *webManager = [[WebManager alloc] init];
             
             [webManager AsyncProcess:@"/user/fblogin" method:POST parameters:dicRequest success:^(MKNetworkOperation *networkOperation) {
                 [loadingHUD dismiss];
                 
                 NSDictionary *response = networkOperation.responseJSON;
                 [[DataManager shareDataManager] setUserInfo:response];
                 
                 NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
                 [pref setObject:@"/user/fblogin" forKey:@"apiName"];
                 [pref setObject:dicRequest forKey:@"loginRequest"];
                 [pref synchronize];
                 
                 [self showErrorWithString:nil code:ERROR_NONE];
                 [self gotoDeliveryLocationScreen];
                 
             } failure:^(MKNetworkOperation *errorOp, NSError *error) {
                 
                 [loadingHUD dismiss];
                 
                 if (error.code == 403 || error.code == 404)
                 {
                     [self gotoPhoneNumberScreen:user];
                     return;
                 }
                 else
                 {
                     NSString *strMessage = [[DataManager shareDataManager] getErrorMessage:errorOp.responseJSON];
                     if (strMessage == nil)
                         strMessage = error.localizedDescription;
                     
                     MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:strMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
                     [alertView showInView:self.view];
                     alertView = nil;
                     return;
                 }
                 
             } isJSON:NO];
         }
         else
         {
             [loadingHUD dismiss];
             
             MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Error" message:error.debugDescription delegate:self cancelButtonTitle:@"OK" otherButtonTitle:nil];
             [alertView showInView:self.view];
             alertView = nil;
             return;
         }
     }];
}

- (IBAction)onRegisterWithFacebook:(id)sender
{
    [self closeKeyboard];
    
    FacebookManager *fbManager = [FacebookManager sharedInstance];
    if ([fbManager isSessionOpen])
    {
        [self reqFacebookUserInfo];
    }
    else
    {
        [fbManager login];
    }
}

- (void)processRegister
{
    NSString *strEmail = self.txtEmail.text;
    NSString *strPassword = self.txtPassword.text;
    NSString *strUserName = self.txtYourname.text;
    NSString *strPhoneNumber = self.txtPhoneNumber.text;
    
    NSDictionary* loginInfo = @{
                                @"name" : strUserName,
                                @"email" : strEmail,
                                @"phone" : strPhoneNumber,
                                @"password" : strPassword,
                                };
    
    NSDictionary *dicRequest = @{@"data" : [loginInfo jsonEncodedKeyValueString]};
    WebManager *webManager = [[WebManager alloc] init];
    
    JGProgressHUD *loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Registering...";
    [loadingHUD showInView:self.view];
    
    [webManager AsyncProcess:@"/user/signup" method:POST parameters:dicRequest success:^(MKNetworkOperation *networkOperation) {
        [loadingHUD dismiss];
        
        NSDictionary *response = networkOperation.responseJSON;
        [[DataManager shareDataManager] setUserInfo:response];
        
        NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
        [pref setObject:@"/user/login" forKey:@"apiName"];
        
        NSDictionary *loginRequest = @{
                                       @"email" : strEmail,
                                       @"password" : strPassword,
                                       };
        NSDictionary *saveRequest = @{@"data" : [loginRequest jsonEncodedKeyValueString]};
        [pref setObject:saveRequest forKey:@"loginRequest"];
        [pref synchronize];
        
        [self showErrorWithString:nil code:ERROR_NONE];
        [self gotoDeliveryLocationScreen];
        
    } failure:^(MKNetworkOperation *errorOp, NSError *error) {
        
        [loadingHUD dismiss];

        NSString *strMessage = [[DataManager shareDataManager] getErrorMessage:errorOp.responseJSON];
        if (strMessage == nil)
            strMessage = error.localizedDescription;
        
        if (error.code == 400)
            [self showErrorWithString:strMessage code:ERROR_PASSWORD];
        else if (error.code == 409)
            [self showErrorWithString:strMessage code:ERROR_NO_EMAIL];
        else
            [self showErrorWithString:strMessage code:ERROR_EMAIL];
        
    } isJSON:NO];
}

- (void)doRegister
{
    [self closeKeyboard];
    
    if (self.txtYourname.text.length == 0)
    {
        [self showErrorWithString:@"Please enter a valid user name." code:ERROR_USERNAME];
        return;
    }
    
    NSString *strEmail = self.txtEmail.text;
    if (strEmail.length == 0)
    {
        [self showErrorWithString:@"Please enter a email address." code:ERROR_EMAIL];
        return;
    }
    
    if (![DataManager isValidMailAddress:strEmail])
    {
        [self showErrorWithString:@"Please enter a valid email address." code:ERROR_EMAIL];
        return;
    }
    
    NSString *strPhoneNumber = self.txtPhoneNumber.text;
    if (strPhoneNumber.length == 0)
    {
        [self showErrorWithString:@"Please enter a phone number." code:ERROR_PHONENUMBER];
        return;
    }
    
    if (![DataManager isValidPhoneNumber:strPhoneNumber])
    {
        [self showErrorWithString:@"Please enter a valid phone number." code:ERROR_PHONENUMBER];
        return;
    }
    
    if (self.txtPassword.text.length == 0)
    {
        [self showErrorWithString:@"Please enter a valid password." code:ERROR_PASSWORD];
        return;
    }
    
    [self processRegister];
}

- (IBAction)onRegister:(id)sender
{
    [self doRegister];
}

- (IBAction)onSignin:(id)sender
{
    [self closeKeyboard];
    
    [self performSegueWithIdentifier:@"SignIn" sender:nil];
}

- (IBAction)onSignInWithEmail:(id)sender
{
    [self performSegueWithIdentifier:@"SignIn" sender:self.txtEmail.text];
}

- (IBAction)onPrivacyPolicy:(id)sender
{
    [self closeKeyboard];
    
    [self performSegueWithIdentifier:@"Terms" sender:[NSNumber numberWithInt:CONTENT_PRIVACY]];
}

- (IBAction)onTermsAndConditions:(id)sender
{
    [self closeKeyboard];
    
    [self performSegueWithIdentifier:@"Terms" sender:[NSNumber numberWithInt:CONTENT_TERMS]];
}

- (void) showErrorWithString:(NSString *)errorMsg code:(int)errorCode
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
    
    self.btnSignUp.hidden = YES;
    
    UIColor *errorColor = [UIColor colorWithRed:233.0f / 255.0f green:114.0f / 255.0f blue:2.0f / 255.0f alpha:1.0f];
    UIColor *correctColor = [UIColor colorWithRed:109.0f / 255.0f green:117.0f / 255.0f blue:131.0f / 255.0f alpha:1.0f];
    
    switch (errorCode) {
        case ERROR_NONE:
        {
            self.viewError.hidden = YES;
            
            self.txtYourname.textColor = correctColor;
            self.txtEmail.textColor = correctColor;
            self.txtPhoneNumber.textColor = correctColor;
            self.txtPassword.textColor = correctColor;
            
            self.ivYourname.image = [UIImage imageNamed:@"register_icon_username"];
            self.ivEmail.image = [UIImage imageNamed:@"register_icon_email"];
            self.ivPhoneNumber.image = [UIImage imageNamed:@"register_icon_phone"];
            self.ivPassword.image = [UIImage imageNamed:@"register_icon_password"];
        }
            break;
            
        case ERROR_USERNAME:
        {
            self.viewError.hidden = NO;
            
            self.txtYourname.textColor = errorColor;
            self.txtEmail.textColor = correctColor;
            self.txtPhoneNumber.textColor = correctColor;
            self.txtPassword.textColor = correctColor;
            
            self.ivYourname.image = [UIImage imageNamed:@"register_icon_username_err"];
            self.ivEmail.image = [UIImage imageNamed:@"register_icon_email"];
            self.ivPhoneNumber.image = [UIImage imageNamed:@"register_icon_phone"];
            self.ivPassword.image = [UIImage imageNamed:@"register_icon_password"];
        }
            break;
            
        case ERROR_EMAIL:
        {
            self.viewError.hidden = NO;
            
            self.txtYourname.textColor = correctColor;
            self.txtEmail.textColor = errorColor;
            self.txtPhoneNumber.textColor = correctColor;
            self.txtPassword.textColor = correctColor;
            
            self.ivYourname.image = [UIImage imageNamed:@"register_icon_username"];
            self.ivEmail.image = [UIImage imageNamed:@"register_icon_email_err"];
            self.ivPhoneNumber.image = [UIImage imageNamed:@"register_icon_phone"];
            self.ivPassword.image = [UIImage imageNamed:@"register_icon_password"];
        }
            break;
            
        case ERROR_NO_EMAIL:
        {
            self.btnSignUp.hidden = NO;
            
            self.viewError.hidden = NO;
            
            self.txtYourname.textColor = correctColor;
            self.txtEmail.textColor = errorColor;
            self.txtPhoneNumber.textColor = correctColor;
            self.txtPassword.textColor = correctColor;
            
            self.ivYourname.image = [UIImage imageNamed:@"register_icon_username"];
            self.ivEmail.image = [UIImage imageNamed:@"register_icon_email_err"];
            self.ivPhoneNumber.image = [UIImage imageNamed:@"register_icon_phone"];
            self.ivPassword.image = [UIImage imageNamed:@"register_icon_password"];
        }
            break;
            
        case ERROR_PHONENUMBER:
        {
            self.viewError.hidden = NO;
            
            self.txtYourname.textColor = correctColor;
            self.txtEmail.textColor = correctColor;
            self.txtPhoneNumber.textColor = errorColor;
            self.txtPassword.textColor = correctColor;
            
            self.ivYourname.image = [UIImage imageNamed:@"register_icon_username"];
            self.ivEmail.image = [UIImage imageNamed:@"register_icon_email"];
            self.ivPhoneNumber.image = [UIImage imageNamed:@"register_icon_phone_err"];
            self.ivPassword.image = [UIImage imageNamed:@"register_icon_password"];
        }
            break;
            
        case ERROR_PASSWORD:
        {
            self.viewError.hidden = NO;
            
            self.txtYourname.textColor = correctColor;
            self.txtEmail.textColor = correctColor;
            self.txtPhoneNumber.textColor = correctColor;
            self.txtPassword.textColor = errorColor;
            
            self.ivYourname.image = [UIImage imageNamed:@"register_icon_username"];
            self.ivEmail.image = [UIImage imageNamed:@"register_icon_email"];
            self.ivPhoneNumber.image = [UIImage imageNamed:@"register_icon_phone"];
            self.ivPassword.image = [UIImage imageNamed:@"register_icon_password_err"];
        }
            break;
            
        default:
        case ERROR_UNKNOWN:
        {
            self.viewError.hidden = NO;
            
            self.txtYourname.textColor = correctColor;
            self.txtEmail.textColor = correctColor;
            self.txtPhoneNumber.textColor = correctColor;
            self.txtPassword.textColor = correctColor;
            
            self.ivYourname.image = [UIImage imageNamed:@"register_icon_username"];
            self.ivEmail.image = [UIImage imageNamed:@"register_icon_email"];
            self.ivPhoneNumber.image = [UIImage imageNamed:@"register_icon_phone"];
            self.ivPassword.image = [UIImage imageNamed:@"register_icon_password"];
        }
            break;
    }
}

- (void) gotoPhoneNumberScreen:(NSDictionary<FBGraphUser> *)userInfo
{
    [self performSegueWithIdentifier:@"PhoneNumber" sender:userInfo];
}

- (void) gotoDeliveryLocationScreen
{
    [self dissmodal];
    //[self performSegueWithIdentifier:@"DeliveryLocation" sender:nil];
}

- (void) closeKeyboard
{
    [self.txtYourname resignFirstResponder];
    [self.txtEmail resignFirstResponder];
    [self.txtPhoneNumber resignFirstResponder];
    [self.txtPassword resignFirstResponder];
    
    _activeField = nil;
}

- (IBAction)onTextChanged:(id)sender
{
    [self updateUI];
}

- (void)updateUI
{
    NSString *strUserName = self.txtYourname.text;
    NSString *strEmail = self.txtEmail.text;
    NSString *strPhoneNumber = self.txtPhoneNumber.text;
    NSString *strPassword = self.txtPassword.text;
    
    BOOL isValid = (strUserName.length > 0 &&
                    strEmail.length > 0 &&
                    [DataManager isValidMailAddress:strEmail] &&
                    strPhoneNumber.length > 0 &&
                    [DataManager isValidPhoneNumber:strPhoneNumber] &&
                    strPassword.length > 0);

//    self.btnRegister.enabled = isValid;
    if (isValid)
        [self.btnRegister setBackgroundColor:[UIColor colorWithRed:135.0f / 255.0f green:178.0f / 255.0f blue:96.0f / 255.0f alpha:1.0f]];
    else
        [self.btnRegister setBackgroundColor:[UIColor colorWithRed:122.0f / 255.0f green:133.0f / 255.0f blue:146.0f / 255.0f alpha:1.0f]];
}

#pragma mark UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    _activeField = textField;
    [self showSignUpButton];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    _activeField = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.txtYourname)
    {
        [self.txtEmail becomeFirstResponder];
    }
    else if (textField == self.txtEmail)
    {
        [self.txtPhoneNumber becomeFirstResponder];
    }
    else if (textField == self.txtPhoneNumber)
    {
        [self.txtPassword  becomeFirstResponder];
    }
    else
    {
        [self doRegister];
    }
    
    return YES;
}

#pragma mark FBManagerDelegate

-(void)FBLogin:(BOOL)flag
{
    [self reqFacebookUserInfo];
}

@end
