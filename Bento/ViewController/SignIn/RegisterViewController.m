//
//  RegisterViewController.m
//  Bento
//
//  Created by hanjinghe on 1/7/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "RegisterViewController.h"

#import "FaqViewController.h"

#import <FacebookSDK/FacebookSDK.h>

typedef enum : NSUInteger {
    ERROR_NONE,
    ERROR_USERNAME,
    ERROR_EMAIL,
    ERROR_PHONENUMBER,
    ERROR_PASSWORD
} ERROR_TYPE;

@interface RegisterViewController ()

@property (nonatomic, assign) IBOutlet UIScrollView *svMain;

@property (nonatomic, assign) IBOutlet UIView *viewError;
@property (nonatomic, assign) IBOutlet UILabel *lblError;

@property (nonatomic, assign) IBOutlet UIView *viewRegisterWithFacebook;

@property (nonatomic, assign) IBOutlet UIButton *btnRegister;

@property (nonatomic, assign) IBOutlet UITextField *txtYourname;
@property (nonatomic, assign) IBOutlet UITextField *txtEmail;
@property (nonatomic, assign) IBOutlet UITextField *txtPhoneNumber;
@property (nonatomic, assign) IBOutlet UITextField *txtPassword;

@property (nonatomic, assign) IBOutlet UIImageView *ivYourname;
@property (nonatomic, assign) IBOutlet UIImageView *ivEmail;
@property (nonatomic, assign) IBOutlet UIImageView *ivPhoneNumber;
@property (nonatomic, assign) IBOutlet UIImageView *ivPassword;


@end

@implementation RegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.viewRegisterWithFacebook.layer.cornerRadius = 3;
    self.viewRegisterWithFacebook.clipsToBounds = YES;
    
    self.btnRegister.layer.cornerRadius = 3;
    self.btnRegister.clipsToBounds = YES;
    
    self.svMain.contentSize = CGSizeMake(self.svMain.frame.size.width, 504);
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
    
    if([segue.identifier isEqualToString:@"Terms"])
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

- (void) collapseScrollView:(float)keyboardHeight
{
    self.svMain.frame = CGRectMake(self.svMain.frame.origin.x, self.svMain.frame.origin.y, self.svMain.frame.size.width, self.view.frame.size.height - self.svMain.frame.origin.y - keyboardHeight);
}

- (void) expandScrollView
{
    self.svMain.frame = CGRectMake(self.svMain.frame.origin.x, self.svMain.frame.origin.y, self.svMain.frame.size.width, self.view.frame.size.height - self.svMain.frame.origin.y);
}

- (IBAction)onBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onRegisterWithFacebook:(id)sender
{
    [self gotoPhoneNumberScreen];
}

- (IBAction)onRegister:(id)sender
{
    if(self.txtYourname.text.length == 0)
    {
        [self showErrorWithString:@"Please enter a valid user name." code:ERROR_USERNAME];
        return;
    }
    
    if(self.txtEmail.text.length == 0)
    {
        [self showErrorWithString:@"Please enter a valid email address." code:ERROR_EMAIL];
        return;
    }
    
    if(self.txtPhoneNumber.text.length == 0)
    {
        [self showErrorWithString:@"Please enter a valid phone number." code:ERROR_PHONENUMBER];
        return;
    }
    
    if(self.txtPassword.text.length == 0)
    {
        [self showErrorWithString:@"Please enter a valid password." code:ERROR_PASSWORD];
        return;
    }
    
    [self showErrorWithString:nil code:ERROR_NONE];
    
    [self performSelector:@selector(gotoPhoneNumberScreen) withObject:nil afterDelay:1.0f];
}

- (IBAction)onSignin:(id)sender
{
    [self performSegueWithIdentifier:@"SignIn" sender:nil];
}

- (IBAction)onPrivacyPolicy:(id)sender
{
    [self performSegueWithIdentifier:@"Terms" sender:[NSNumber numberWithInt:CONTENT_PRIVACY]];
}

- (IBAction)onTermsAndConditions:(id)sender
{
    [self performSegueWithIdentifier:@"Terms" sender:[NSNumber numberWithInt:CONTENT_TERMS]];
}

- (void) showErrorWithString:(NSString *)errorMsg code:(int)errorCode
{
    if(errorMsg == nil || errorMsg.length == 0)
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
            break;
    }
}

- (void) gotoPhoneNumberScreen
{
    [self performSegueWithIdentifier:@"PhoneNumber" sender:nil];
}

- (void) gotoDeliveryLocationScreen
{
    [self performSegueWithIdentifier:@"DeliveryLocation" sender:nil];
}

- (void) closeKeyboard
{
    [self.txtYourname resignFirstResponder];
    [self.txtEmail resignFirstResponder];
    [self.txtPhoneNumber resignFirstResponder];
    [self.txtPassword resignFirstResponder];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if(textField == self.txtYourname)
    {
        [self.txtEmail becomeFirstResponder];
    }
    else if(textField == self.txtEmail)
    {
        [self.txtPhoneNumber becomeFirstResponder];
    }
    else if(textField == self.txtPhoneNumber)
    {
        [self.txtPassword  becomeFirstResponder];
    }
    else
    {
        [self closeKeyboard];
    }
    
    return YES;
}

@end
