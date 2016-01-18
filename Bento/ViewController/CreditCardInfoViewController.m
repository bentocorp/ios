//
//  CreditCardInfoViewController.m
//  settings
//
//  Created by Joseph Lau on 4/23/15.
//  Copyright (c) 2015 Joseph Lau. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#import "CreditCardInfoViewController.h"
#import "DataManager.h"
#import "WebManager.h"
#import "JGProgressHUD.h"
#import "MyAlertView.h"
#import "EnterCreditCardViewController.h"

#import "BentoShop.h"

#import "UIColor+CustomColors.h"

#import "UIColor+CustomColors.h"

// Stripe
#import "Stripe.h"
#import "STPToken.h"
#import "Stripe+ApplePay.h"
#import <PassKit/PassKit.h>

#import "PTKCardType.h"
#import "PTKCardNumber.h"
#import "PKPayment+STPTestKeys.h"

#ifdef DEBUG
#import "STPTestPaymentAuthorizationViewController.h"
#endif

#define KEY_PROMO_CODE @"promo_code"
#define KEY_PROMO_DISCOUNT @"promo_discount"

//#define APPLE_MERCHANT_ID @"merchant.com.bento"
#define APPLE_MERCHANT_ID @"merchant.com.somethingnew.bento"

@interface CreditCardInfoViewController () <EnterCreditCardViewControllerDelegate>

@end

@implementation CreditCardInfoViewController
{
    NSDictionary *currentUserInfo;
    
    UIImageView *creditCardImage;
    UILabel *creditCardDigitsLabel;
    
    JGProgressHUD *loadingHUD;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    currentUserInfo = [[DataManager shareDataManager] getUserInfo];

    self.view.backgroundColor = [UIColor bentoBackgroundGray];
    
    // navigation bar color
    UIView *navigationBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 65)];
    navigationBarView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navigationBarView];
    
    // title label
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 2 - 110, 20, 220, 45)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    titleLabel.textColor = [UIColor bentoTitleGray];
    titleLabel.text = @"Credit Card";
    [self.view addSubview:titleLabel];
    
    // back button
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 50, 45)];
    [backButton setImage:[UIImage imageNamed:@"nav_btn_back"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(onBackButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
    
    // line separators
    UIView *longLineSepartor1 = [[UIView alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, 1)];
    longLineSepartor1.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
    [self.view addSubview:longLineSepartor1];
    
    UIView *longLineSepartor2 = [[UIView alloc] initWithFrame:CGRectMake(0, 144, SCREEN_WIDTH, 1)];
    longLineSepartor2.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
    [self.view addSubview:longLineSepartor2];
    
    UIView *longLineSepartor3 = [[UIView alloc] initWithFrame:CGRectMake(0, 190, SCREEN_WIDTH, 1)];
    longLineSepartor3.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
    [self.view addSubview:longLineSepartor3];
    
    // white background view
    UIView *whiteBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 145, SCREEN_WIDTH, 45)];
    whiteBackgroundView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:whiteBackgroundView];

    // credit card image
    creditCardImage = [[UIImageView alloc] initWithFrame:CGRectMake(20, whiteBackgroundView.frame.size.height/2 - (29.2/2), 40, 29.2)];
    [creditCardImage setClipsToBounds:YES];
    creditCardImage.contentMode = UIViewContentModeScaleAspectFill;
    [whiteBackgroundView addSubview:creditCardImage];
    
    // credit card digits
    creditCardDigitsLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, 12, 150, 21)];
    creditCardDigitsLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    creditCardDigitsLabel.textColor = [UIColor bentoTitleGray];
    [whiteBackgroundView addSubview:creditCardDigitsLabel];
    
    // change credit card button
//    UIButton *changeButton = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 80, whiteBackgroundView.frame.size.height/2 - 15, 80, 30)];
//    if ([currentUserInfo[@"card"] isKindOfClass:[NSNull class]])
//        [changeButton setTitle:@"ADD" forState:UIControlStateNormal];
//    else
//        [changeButton setTitle:@"CHANGE" forState:UIControlStateNormal];
//    [changeButton setTitleColor:[UIColor bentoBrandGreen] forState:UIControlStateNormal];
//    changeButton.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
//    [changeButton addTarget:self action:@selector(onChange) forControlEvents:UIControlEventTouchUpInside];
//    [whiteBackgroundView addSubview:changeButton];
}

-(void)viewWillAppear:(BOOL)animated
{
    if ([currentUserInfo[@"card"] isKindOfClass:[NSNull class]]) {
        // no card info
        creditCardImage.image = [UIImage imageNamed:@"placeholder"];
    }
    else {
        // has card info
        creditCardImage.image = [UIImage imageNamed:[currentUserInfo[@"card"][@"brand"] lowercaseString]];
        creditCardDigitsLabel.text = currentUserInfo[@"card"][@"last4"];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
}

- (void)noConnection
{
    if (loadingHUD == nil) {
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

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
}

- (void)onChange
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EnterCreditCardViewController *enterCreditCardViewController = [storyboard instantiateViewControllerWithIdentifier:@"EnterCreditCardViewController"];
    enterCreditCardViewController.delegate = self;
    [self.navigationController presentViewController:enterCreditCardViewController animated:YES completion:nil];
}

#pragma mark EnterCreditCardViewControllerDelegate

- (void)setCardInfo:(STPCard *)cardInfo
{
    [[DataManager shareDataManager] setCreditCard:cardInfo];
    
    [self updateCardInfo];
}

- (void)updateCardInfo
{
    NSLog(@"updated user info - %@", [[DataManager shareDataManager] getUserInfo]);
    
    PaymentMethod curPaymentMethod = [[DataManager shareDataManager] getPaymentMethod];
    if (curPaymentMethod == Payment_ApplePay)
    {
        [creditCardImage setImage:[UIImage imageNamed:@"orderconfirm_image_applepay"]];
        creditCardDigitsLabel.text = @"Apple Pay";
    }
    else if (curPaymentMethod == Payment_Server)
    {
        NSDictionary *userInfo = [[DataManager shareDataManager] getUserInfo];
        NSDictionary *cardInfo = [userInfo objectForKey:@"card"];
        NSString *strCardType = [[cardInfo objectForKey:@"brand"] lowercaseString];
        NSString *strCardNumber = [cardInfo objectForKey:@"last4"];
        
        [self updatePaymentInfo:strCardType cardNumber:strCardNumber paymentMethod:curPaymentMethod];
    }
    else if (curPaymentMethod == Payment_CreditCard)
    {
        STPCard *cardInfo = [[DataManager shareDataManager] getCreditCard];
        PTKCardNumber *cardNumber = [PTKCardNumber cardNumberWithString:cardInfo.number];
        PTKCardType cardType = [cardNumber cardType];
        
        switch (cardType) {
            case PTKCardTypeAmex:
                [self updatePaymentInfo:@"amex" cardNumber:cardNumber.last4 paymentMethod:curPaymentMethod];
                break;
            case PTKCardTypeDinersClub:
                [self updatePaymentInfo:@"diners" cardNumber:cardNumber.last4 paymentMethod:curPaymentMethod];
                break;
            case PTKCardTypeDiscover:
                [self updatePaymentInfo:@"discover" cardNumber:cardNumber.last4 paymentMethod:curPaymentMethod];
                break;
            case PTKCardTypeJCB:
                [self updatePaymentInfo:@"jcb" cardNumber:cardNumber.last4 paymentMethod:curPaymentMethod];
                break;
            case PTKCardTypeMasterCard:
                [self updatePaymentInfo:@"mastercard" cardNumber:cardNumber.last4 paymentMethod:curPaymentMethod];
                break;
            case PTKCardTypeVisa:
                [self updatePaymentInfo:@"visa" cardNumber:cardNumber.last4 paymentMethod:curPaymentMethod];
                break;
            default:
                [self updatePaymentInfo:@"" cardNumber:@"" paymentMethod:curPaymentMethod];
                break;
        }
        
        NSLog(@"card number - %@", cardInfo.last4);
        
    }
    else if (curPaymentMethod == Payment_None)
    {
        [creditCardImage setImage:[UIImage imageNamed:@"orderconfirm_image_credit"]];
        creditCardDigitsLabel.text = @"";
    }
}


- (void)updatePaymentInfo:(NSString *)strCardType cardNumber:(NSString *)strCardNumber paymentMethod:(PaymentMethod)paymentMethod
{
    NSString *strImageName = @"placeholder";
    NSString *strPaymentMethod = @"";
    
    if ([strCardType isEqualToString:@"applepay"])
    {
        strImageName = @"orderconfirm_image_applepay";
        strPaymentMethod = @"Apple Pay";
    }
    else if ([strCardType isEqualToString:@"amex"])
    {
        strImageName = @"amex";
        strPaymentMethod = strCardNumber;
    }
    else if ([strCardType isEqualToString:@"diners"])
    {
        strImageName = @"diners";
        strPaymentMethod = strCardNumber;
    }
    else if ([strCardType isEqualToString:@"discover"])
    {
        strImageName = @"discover";
        strPaymentMethod = strCardNumber;
    }
    else if ([strCardType isEqualToString:@"jcb"])
    {
        strImageName = @"jcb";
        strPaymentMethod = strCardNumber;
    }
    else if ([strCardType isEqualToString:@"mastercard"])
    {
        strImageName = @"mastercard";
        strPaymentMethod = strCardNumber;
    }
    else if ([strCardType isEqualToString:@"visa"])
    {
        strImageName = @"visa";
        strPaymentMethod= strCardNumber;
    }
    
    creditCardDigitsLabel.text = strPaymentMethod;
    [creditCardImage setImage:[UIImage imageNamed:strImageName]];
    
    
    NSMutableDictionary *currentUserInfo2 = [[[DataManager shareDataManager] getUserInfo] mutableCopy];
    currentUserInfo2[@"card"] = @{
                                 @"brand": strImageName,
                                 @"last4": strCardNumber
                                 };
    [[DataManager shareDataManager] setUserInfo:currentUserInfo2 paymentMethod:paymentMethod];// This should fix the payment issue, added paymentMethod
    
    NSLog(@"Update Payment Info, %@", currentUserInfo2[@"card"]);
    
    [self viewDidLoad];
}

-(void)onBackButton
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
