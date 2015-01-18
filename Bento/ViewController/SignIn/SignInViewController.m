//
//  SignInViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "SignInViewController.h"

#import "MyAlertView.h"

@interface SignInViewController ()

@property (nonatomic, assign) IBOutlet UIScrollView *svMain;

@property (nonatomic, assign) IBOutlet UIView *viewFacebook;
@property (nonatomic, assign) IBOutlet UIButton *btnSignIn;

@property (nonatomic, assign) IBOutlet UITextField *txtEmail;
@property (nonatomic, assign) IBOutlet UITextField *txtPassword;

@end

@implementation SignInViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.svMain.contentSize = CGSizeMake(self.svMain.frame.size.width, 504);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

- (void)hideKeyboard
{
    [self.txtEmail resignFirstResponder];
    [self.txtPassword resignFirstResponder];
}

- (void)showErrorMessage:(NSString *)strMessage
{
    
}

- (IBAction)onBack:(id)sender
{
    [self hideKeyboard];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)isValidMailAddress:(NSString*)strMailAddr
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:strMailAddr];
}

- (BOOL)processSignin
{
    return YES;
}

- (IBAction)onSignIn:(id)sender
{
    NSString *strEmail = self.txtEmail.text;
    NSString *strPassword = self.txtPassword.text;
    
    if (strEmail.length == 0)
    {
        [self showErrorMessage:@"Please input e-mail address."];
        return;
    }
    
    if (![self isValidMailAddress:strEmail])
    {
        [self showErrorMessage:@"Please input a vaild e-mail address."];
        return;
    }
    
    if (strPassword.length == 0)
    {
        [self showErrorMessage:@"Please input the password."];
        return;
    }
    
    if ([self processSignin])
        [self gotoDeliveryLocationScreen];
}

- (IBAction)onSignInWithFacebook:(id)sender
{
    [self gotoDeliveryLocationScreen];
}

- (void) gotoDeliveryLocationScreen
{
    [self performSegueWithIdentifier:@"DeliveryLocation" sender:nil];
}


@end
