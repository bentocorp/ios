//
//  EnterCreditCardViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "EnterCreditCardViewController.h"

#import "MyAlertView.h"

#import "AppStrings.h"

#import <Stripe/Stripe.h>

#import <PassKit/PassKit.h>

#import "JGProgressHUD.h"

#import "BentoShop.h"

#import "Mixpanel.h"

#import "UIColor+CustomColors.h"

@interface EnterCreditCardViewController () <STPPaymentCardTextFieldDelegate>

@property (nonatomic, weak) IBOutlet UILabel *lblTitle;

@property (nonatomic, weak) IBOutlet UIButton *btnContinue;

@property (nonatomic, weak) IBOutlet UIView *viewInput;

@property (nonatomic) STPPaymentCardTextField *paymentTextField;

@end

@implementation EnterCreditCardViewController
{
    STPCardParams *creditCard;
    JGProgressHUD *loadingHUD;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"Viewed Credit Card Screen For First Time"] == nil) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Viewed Credit Card Screen For First Time"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[Mixpanel sharedInstance] track:@"Viewed Credit Card Screen For First Time"];
    }
    
    self.lblTitle.text = [[AppStrings sharedInstance] getString:CREDITCARD_TITLE];
    [self.btnContinue setTitle:[[AppStrings sharedInstance] getString:CREDITCARD_BUTTON_CONTINUE] forState:UIControlStateNormal];
    
    // Credit Card View
    self.paymentTextField = [[STPPaymentCardTextField alloc] initWithFrame:CGRectMake(20, 0, self.viewInput.frame.size.width - 40, self.viewInput.frame.size.height)];
    self.paymentTextField.layer.borderWidth = 0;
    self.paymentTextField.delegate = self;
    [self.viewInput addSubview:self.paymentTextField];
    
    [self.paymentTextField becomeFirstResponder];
    
    creditCard = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willChangeKeyboardFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimerOnViewedScreen) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endTimerOnViewedScreen) name:@"enteringBackground" object:nil];
    
    self.btnContinue.enabled = NO;
    [self.btnContinue setBackgroundColor:[UIColor bentoButtonGray]];
    
    [self startTimerOnViewedScreen];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
    
    [self endTimerOnViewedScreen];
}

#pragma mark Duration on screen
- (void)startTimerOnViewedScreen {
    [[Mixpanel sharedInstance] timeEvent:@"Viewed Credit Card Screen"];
}

- (void)endTimerOnViewedScreen {
    [[Mixpanel sharedInstance] track:@"Viewed Credit Card Screen"];
}

- (void)noConnection {
    if (loadingHUD == nil) {
        loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        loadingHUD.textLabel.text = @"Waiting for internet connectivity...";
        [loadingHUD showInView:self.view];
    }
}

- (void)yesConnection {
    [loadingHUD dismiss];
    loadingHUD = nil;
}

- (void)willShowKeyboard:(NSNotification*)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    [self moveContinueButtonWithKeyboardHeight:keyboardFrameBeginRect.size.height];
}

- (void)willChangeKeyboardFrame:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    [self moveContinueButtonWithKeyboardHeight:keyboardFrameBeginRect.size.height];
}

- (void)willHideKeyboard:(NSNotification *)notification {
    [self moveContinueButtonWithKeyboardHeight:0];
}

- (void)moveContinueButtonWithKeyboardHeight:(float) height {
    [UIView animateWithDuration:0.3f animations:^{
        
        CGFloat yCenter = self.view.frame.size.height - (self.btnContinue.frame.size.height / 2 + 40 + height);
        if (yCenter < 64 + self.viewInput.frame.origin.y + self.viewInput.frame.size.height + self.btnContinue.frame.size.height / 2) {
            yCenter = 64 + self.viewInput.frame.origin.y + self.viewInput.frame.size.height + self.btnContinue.frame.size.height / 2;
        }
        
        self.btnContinue.center = CGPointMake(self.btnContinue.center.x, yCenter);
    }];
}

- (IBAction)onClose:(id)sender {
    [self hideKeyboard];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onClear:(id)sender {
    [self.paymentTextField clear];
}

- (IBAction)onContinueToPayment:(id)sender {
    
    if (self.delegate != nil) {
        
        [self.delegate setCardInfo:creditCard];
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"Saved Credit Card For First Time"] == nil) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Saved Credit Card For First Time"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [[Mixpanel sharedInstance] track:@"Saved Credit Card For First Time"];
        }
    }
    
    [self hideKeyboard];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)hideKeyboard {
    [self.paymentTextField resignFirstResponder];
}

#pragma mark STPPaymentCardTextFieldDelegate

- (void)paymentCardTextFieldDidChange:(STPPaymentCardTextField *)textField {
    if (textField.isValid) {
        STPCardParams *card = [[STPCard alloc] init];
        card.number = textField.cardNumber;
        card.expMonth = textField.expirationMonth;
        card.expYear = textField.expirationYear;
        card.cvc = textField.cvc;
        creditCard = card;
        
        self.btnContinue.enabled = YES;
        [self.btnContinue setBackgroundColor:[UIColor bentoBrandGreen]];
    }
    else {
        creditCard = nil;
        self.btnContinue.enabled = NO;
        [self.btnContinue setBackgroundColor:[UIColor bentoButtonGray]];
    }
}

@end
