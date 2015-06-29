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

#import "Stripe.h"
#import "PTKView.h"
#import "PTKTextField.h"

#import <PassKit/PassKit.h>

#import "JGProgressHUD.h"

#import "BentoShop.h"

@interface EnterCreditCardViewController () <PTKViewDelegate>
{
    STPCard *_creditCard;
    JGProgressHUD *loadingHUD;
}

@property (nonatomic, assign) IBOutlet UILabel *lblTitle;

@property (nonatomic, assign) IBOutlet UILabel *lblMessage;

@property (nonatomic, assign) IBOutlet UILabel *lblPrice;

@property (nonatomic, assign) IBOutlet UIButton *btnContinue;

@property (nonatomic, assign) IBOutlet UIView *viewInput;

@property (weak, nonatomic) PTKView *paymentView;

@end

@implementation EnterCreditCardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.lblTitle.text = [[AppStrings sharedInstance] getString:CREDITCARD_TITLE];
    self.lblMessage.text = [[AppStrings sharedInstance] getString:CREDITCARD_TEXT];
    
    NSInteger salePrice = [[AppStrings sharedInstance] getInteger:SALE_PRICE];
    NSInteger unitPrice = [[AppStrings sharedInstance] getInteger:ABOUT_PRICE];
    
    if (salePrice != 0 && salePrice < unitPrice)
        self.lblPrice.text = [NSString stringWithFormat:@"$%ld", (long)salePrice];
    else
        self.lblPrice.text = [NSString stringWithFormat:@"$%ld", (long)unitPrice];
    
    // make this dynamic, Save or Continue To Summary- [[AppStrings sharedInstance] getString:CREDITCARD_BUTTON_CONTINUE]
    [self.btnContinue setTitle:@"SAVE CREDIT CARD" forState:UIControlStateNormal];
    
    // Credit Card View
    PTKView *view = [[PTKView alloc] initWithFrame:self.viewInput.frame];
    view.center = CGPointMake(self.viewInput.frame.size.width / 2, self.viewInput.frame.size.height / 2);
    self.paymentView = view;
    self.paymentView.delegate = self;
    [self.viewInput addSubview:self.paymentView];
    
    NSArray *subviews = self.paymentView.subviews;
    for (UIView *subview in subviews) {
        if([subview isKindOfClass:[UIImageView class]] && subview != self.paymentView.placeholderView)
        {
            subview.hidden = YES;
        }
    }
    
    _creditCard = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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
    
    self.btnContinue.enabled = NO;
    [self.btnContinue setBackgroundColor:[UIColor colorWithRed:122.0f / 255.0f green:133.0f / 255.0f blue:146.0f / 255.0f alpha:1.0f]];
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
    
    [self moveContinueButtonWithKeyboardHeight:keyboardFrameBeginRect.size.height];
}

- (void) willChangeKeyboardFrame:(NSNotification *)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    [self moveContinueButtonWithKeyboardHeight:keyboardFrameBeginRect.size.height];
}

- (void) willHideKeyboard:(NSNotification *)notification
{
    [self moveContinueButtonWithKeyboardHeight:0];
}

- (void) moveContinueButtonWithKeyboardHeight:(float) height
{
    [UIView animateWithDuration:0.3f animations:^{
        
        CGFloat yCenter = self.view.frame.size.height - (self.btnContinue.frame.size.height / 2 + 40 + height);
        if (yCenter < 64 + self.viewInput.frame.origin.y + self.viewInput.frame.size.height + self.btnContinue.frame.size.height / 2)
            yCenter = 64 + self.viewInput.frame.origin.y + self.viewInput.frame.size.height + self.btnContinue.frame.size.height / 2;
        
        self.btnContinue.center = CGPointMake(self.btnContinue.center.x, yCenter);
        
    } completion:^(BOOL finished) {
        
    }];
}

- (IBAction)onClose:(id)sender
{
    [self hideKeyboard];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onClear:(id)sender
{
    ((UITextField *)self.paymentView.cardNumberField).text = @"";
    ((UITextField *)self.paymentView.cardExpiryField).text = @"";
    ((UITextField *)self.paymentView.cardCVCField).text = @"";
    
    self.paymentView.placeholderView.image = [UIImage imageNamed:@"placeholder"];
}

- (IBAction)onContinueToPayment:(id)sender
{
    if (self.delegate != nil)
        [self.delegate setCardInfo:_creditCard];
    
    [self hideKeyboard];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)hideKeyboard
{
    [self.paymentView resignFirstResponder];
    [self.paymentView.cardNumberField resignFirstResponder];
    [self.paymentView.cardExpiryField resignFirstResponder];
    [self.paymentView.cardCVCField resignFirstResponder];
}

#pragma mark PTKViewDelegate

- (void)paymentView:(PTKView *)view withCard:(PTKCard *)card isValid:(BOOL)valid
{
    // Toggle navigation, for example
    if (valid)
    {
        STPCard *stpCard = [[STPCard alloc] init];
        stpCard.number = card.number;
        stpCard.expMonth = card.expMonth;
        stpCard.expYear = card.expYear;
        stpCard.cvc = card.cvc;
        _creditCard = stpCard;
        
        self.btnContinue.enabled = YES;
        [self.btnContinue setBackgroundColor:[UIColor colorWithRed:135.0f / 255.0f green:178.0f / 255.0f blue:96.0f / 255.0f alpha:1.0f]];
    }
    else
    {
        _creditCard = nil;
        self.btnContinue.enabled = NO;
        [self.btnContinue setBackgroundColor:[UIColor colorWithRed:122.0f / 255.0f green:133.0f / 255.0f blue:146.0f / 255.0f alpha:1.0f]];
        
//        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:@"Invalid credit card" delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
//        [alertView showInView:self.view];
//        alertView = nil;
    }
}

@end
