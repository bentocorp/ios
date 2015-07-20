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
#import "Mixpanel.h"

#import "BentoShop.h"

#import "CompleteOrderViewController.h"

@interface RegisterViewController () <FBManagerDelegate, MyAlertViewDelegate>

@property (nonatomic, weak) IBOutlet UILabel *lblTitle;

@property (nonatomic, weak) IBOutlet UIScrollView *svMain;

@property (nonatomic, weak) IBOutlet UIView *viewError;
@property (nonatomic, weak) IBOutlet UILabel *lblError;

@property (nonatomic, weak) IBOutlet UIView *viewRegisterWithFacebook;

@property (nonatomic, weak) IBOutlet UIButton *btnRegister;

@property (nonatomic, weak) IBOutlet UITextField *txtYourname;
@property (nonatomic, weak) IBOutlet UITextField *txtEmail;
@property (nonatomic, weak) IBOutlet SHSPhoneTextField *txtPhoneNumber;
@property (nonatomic, weak) IBOutlet UITextField *txtPassword;

@property (nonatomic, weak) IBOutlet UIImageView *ivYourname;
@property (nonatomic, weak) IBOutlet UIImageView *ivEmail;
@property (nonatomic, weak) IBOutlet UIImageView *ivPhoneNumber;
@property (nonatomic, weak) IBOutlet UIImageView *ivPassword;

@property (nonatomic, weak) IBOutlet UIButton *btnPolicy;
@property (nonatomic, weak) IBOutlet UIButton *btnTerms;

@property (nonatomic, weak) IBOutlet UILabel *signInLabel;
@property (nonatomic, weak) IBOutlet UIButton *signInButton;

@end

@implementation RegisterViewController
{
    UITextField *_activeField;
    BOOL beganRegistration;
    JGProgressHUD *loadingHUD;
    Mixpanel *mixpanel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    mixpanel = [Mixpanel sharedInstance];
    
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
        
        // set the last character in attributed text to have a bolder font
        if ([textField.text length] > 0)
        {
            NSString *lastCharacter = [textField.text substringFromIndex:[textField.text length] - 1];
            
            unichar c = [lastCharacter characterAtIndex:0];
            if (c >= '0' && c <= '9')
            {
//                textField.text = (NSString *)atrString;
            }
            
            NSLog(@"Last Character: %@", lastCharacter);
        }
        
        [self updateUI];
    }];
    
    [self.txtPhoneNumber.formatter setDefaultOutputPattern:@"(###) ### - ####"];
//    self.txtPhoneNumber.formatter.prefix = @"+1 ";
    
    // Facebook
    [[FacebookManager sharedInstance] setDelegate:self];
    
    // Tap
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    //
    _activeField = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCurrentMode) name:@"enteredForeground" object:nil];
    
    [self showErrorWithString:nil code:ERROR_NONE];
    
    [self updateUI];
    
    /*----------------*/
    
    // this should run when signed in from checkout
    if ([[DataManager shareDataManager] getUserInfo] != nil)
        [self.navigationController popViewControllerAnimated:NO];
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
    if ([[BentoShop sharedInstance] didModeOrDateChange])
    {
        [(UINavigationController *)self.presentingViewController popToRootViewControllerAnimated:NO];
        [self dismissViewControllerAnimated:YES completion:nil];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
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
    [self closeKeyboard];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)reqFacebookUserInfo
{
    loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Logging in...";
    [loadingHUD showInView:self.view];
    
    [[FacebookManager sharedInstance] loadUserDetailsWithCompletionHandler:^(NSDictionary<FBGraphUser> *user, NSError *error)
     {
         if (error == nil)
         {
             NSString *strMailAddr = [user valueForKey:@"email"];
             if (strMailAddr == nil || strMailAddr.length == 0)
             {
                 [loadingHUD dismiss];
                 
                 MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:@"Error! We need your email to submit your order. We promise, no spam! Do you want to try again?" delegate:self cancelButtonTitle:@"No" otherButtonTitle:@"Yes"];
                 [alertView showInView:self.view];
                 alertView = nil;
                 return;
             }
             
             NSString *strAccessToken = [[[FBSession activeSession] accessTokenData] accessToken];
             
             NSString *strFBID = [user valueForKey:@"id"];
             
             NSDictionary* loginInfo = @{
                                         @"email" : strMailAddr,
                                         @"fb_id" : strFBID,
                                         @"fb_token" : strAccessToken,
                                         };
             
             NSDictionary *dicRequest = @{@"data" : [loginInfo jsonEncodedKeyValueString]};
             WebManager *webManager = [[WebManager alloc] init];
             
             NSString *strRequest = [NSString stringWithFormat:@"%@/user/fblogin", SERVER_URL];
             [webManager AsyncProcess:strRequest method:POST parameters:dicRequest success:^(MKNetworkOperation *networkOperation) {
                 [loadingHUD dismiss];
                 
                 NSDictionary *response = networkOperation.responseJSON;
                 [[DataManager shareDataManager] setUserInfo:response];
                 
                 NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
                 [pref setObject:strRequest forKey:@"apiName"];
                 [pref setObject:dicRequest forKey:@"loginRequest"];
                 [pref synchronize];
                 
                 [self showErrorWithString:nil code:ERROR_NONE];

                 [self signInWithRegisteredData:dicRequest];
                 
                 [self.navigationController dismissViewControllerAnimated:YES completion:nil]; // try first
                
                 [self.navigationController popViewControllerAnimated:YES]; // if ^ doesn't execute, do this
                 
                 [mixpanel track:@"Completed Registration" properties:nil];
                 NSLog(@"COMPLETED REGISTRATION");
                 
             } failure:^(MKNetworkOperation *errorOp, NSError *error) {
                 
                 [loadingHUD dismiss];
                 
                 if (error.code == 403 || error.code == 404)
                 {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         [self gotoPhoneNumberScreen:user];
                     });
                     
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

- (void)doRegisterWithFacebook:(BOOL)isRetry
{
    [self closeKeyboard];
    
    FacebookManager *fbManager = [FacebookManager sharedInstance];
    
    if (isRetry)
        [fbManager login];
    else
    {
        if ([fbManager isSessionOpen])
            [self reqFacebookUserInfo];
        else
            [fbManager login];
    }
}

- (IBAction)onRegisterWithFacebook:(id)sender
{
    [self doRegisterWithFacebook:NO];
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
    
    loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Registering...";
    [loadingHUD showInView:self.view];
    
    NSString *strRequest = [NSString stringWithFormat:@"%@/user/signup", SERVER_URL];
    [webManager AsyncProcess:strRequest method:POST parameters:dicRequest success:^(MKNetworkOperation *networkOperation) {
        [loadingHUD dismiss];
        
//        NSDictionary *response = networkOperation.responseJSON;
//        [[DataManager shareDataManager] setUserInfo:response];
        
        NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
        NSString *strRequest = [NSString stringWithFormat:@"%@/user/login", SERVER_URL];
        [pref setObject:strRequest forKey:@"apiName"];
        
        NSDictionary *loginRequest = @{
                                       @"email" : strEmail,
                                       @"password" : strPassword,
                                       };
        
        NSDictionary *saveRequest = @{@"data" : [loginRequest jsonEncodedKeyValueString]};
        [pref setObject:saveRequest forKey:@"loginRequest"];
        [pref synchronize];
        
        [self showErrorWithString:nil code:ERROR_NONE];
        
        [self signInWithRegisteredData:dicRequest];
        
        [self.navigationController dismissViewControllerAnimated:YES completion:nil]; // try first
        
        [self.navigationController popViewControllerAnimated:YES]; // if ^ doesn't execute, do this
            
        [mixpanel track:@"Completed Registration" properties:nil];
        NSLog(@"COMPLETED REGISTRATION");
        
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

-(void)signInWithRegisteredData:(NSDictionary *)registeredData
{
    WebManager *webManager = [[WebManager alloc] init];
    
    NSString *strRequest = [NSString stringWithFormat:@"%@/user/login", SERVER_URL];
    [webManager AsyncProcess:strRequest method:POST parameters:registeredData success:^(MKNetworkOperation *networkOperation) {
        
        NSDictionary *response = networkOperation.responseJSON;
        [[DataManager shareDataManager] setUserInfo:response];
        NSLog(@"new user data - %@", [[DataManager shareDataManager] getUserInfo]);
        
        NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
        [pref setObject:strRequest forKey:@"apiName"];
        [pref setObject:registeredData forKey:@"loginRequest"];
        [pref synchronize];
        
        // dismiss vc
        [self dismissViewControllerAnimated:YES completion:nil];
        
    } failure:^(MKNetworkOperation *errorOp, NSError *error) {
        
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
    
    if (self.txtPassword.text.length < 6) // min character of 6
    {
        [self showErrorWithString:@"Please enter a minimum of 6 characters." code:ERROR_PASSWORD];
        return;
    }
    
    [self processRegister];
}

- (IBAction)onRegister:(id)sender
{
    [self doRegister];
}

- (IBAction)onPrivacyPolicy:(id)sender
{
    [self closeKeyboard];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FaqViewController *destVC = [storyboard instantiateViewControllerWithIdentifier:@"FAQID"];
    destVC.contentType = CONTENT_PRIVACY;
    [self.navigationController pushViewController:destVC animated:YES];
}

- (IBAction)onTermsAndConditions:(id)sender
{
    [self closeKeyboard];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FaqViewController *destVC = [storyboard instantiateViewControllerWithIdentifier:@"FAQID"];
    destVC.contentType = CONTENT_TERMS;
    [self.navigationController pushViewController:destVC animated:YES];
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
    
    /*------------------------------------------------------------*/
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([[defaults objectForKey:@"cameFromWhichVC"] isEqualToString:@"cameFromSignIn"]) {
        // hide
        self.signInButton.hidden = YES;
        self.signInLabel.hidden = YES;
    }
}

#pragma mark UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    _activeField = textField;
    [self showSignUpButton];
    
    // Track Began Registration
    // only call once per page view
    if (beganRegistration == NO)
    {
        [mixpanel track:@"Began Registration" properties:nil];
        
        beganRegistration = YES;
        
        NSLog(@"BEGAN REGISTRATION");
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    _activeField = nil;
    
    NSString *strEmail = self.txtEmail.text;
    NSString *strPhoneNumber = self.txtPhoneNumber.text;
    
    if (strEmail.length != 0 && ![DataManager isValidMailAddress:strEmail])
    {
        [self showErrorWithString:@"Please enter a valid email address." code:ERROR_EMAIL];
        return;
    }

    if (strPhoneNumber.length != 0 && ![DataManager isValidPhoneNumber:strPhoneNumber])
    {
        [self showErrorWithString:@"Please enter a valid phone number." code:ERROR_PHONENUMBER];
        return;
    }
    
    if (self.txtPassword.text.length != 0 && self.txtPassword.text.length < 6)
    {
        [self showErrorWithString:@"Password requires a minimum of 6 characters." code:ERROR_PASSWORD];
        return;
    }

    [self showErrorWithString:nil code:ERROR_NONE];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.txtYourname)
        [self.txtEmail becomeFirstResponder];
    else if (textField == self.txtEmail)
        [self.txtPhoneNumber becomeFirstResponder];
    else if (textField == self.txtPhoneNumber)
        [self.txtPassword becomeFirstResponder];
    else
        [self doRegister];
    
    return YES;
}

-(void)dismissKeyboard
{
    [self.txtEmail endEditing:YES];
    [self.txtYourname endEditing:YES];
    [self.txtPhoneNumber endEditing:YES];
    [self.txtPassword endEditing:YES];
}

#pragma mark FBManagerDelegate

-(void)FBLogin:(BOOL)flag
{
    [self reqFacebookUserInfo];
}

#pragma mark MyAlertViewDelegate

- (void)doReauthorise
{
    [self doRegisterWithFacebook:YES];
}

- (void)alertView:(MyAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
        [self performSelector:@selector(doReauthorise) withObject:nil];
}

- (IBAction)onSignIn:(id)sender
{
    [self closeKeyboard];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"cameFromRegister" forKey:@"cameFromWhichVC"];
    [defaults synchronize];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *destVC = [storyboard instantiateViewControllerWithIdentifier:@"SignInID"];
    [self.navigationController pushViewController:destVC animated:YES];
}

@end
