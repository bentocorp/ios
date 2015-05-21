	//
//  CompleteOrderViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "CompleteOrderViewController.h"

<<<<<<< HEAD
#import "MyBentoViewController.h"
=======
#import "ServingDinnerViewController.h"
#import "ServingLunchViewController.h"

>>>>>>> 47776439e452e2fc205c2d7569fc58f955c67495
#import "EnterCreditCardViewController.h"
#import "DeliveryLocationViewController.h"

#import "BentoTableViewCell.h"

#import "PromoCodeView.h"

#import "MyAlertView.h"

#import "JGProgressHUD.h"

#import "BentoShop.h"
#import "AppStrings.h"
#import "WebManager.h"
#import "DataManager.h"

#import "SVPlacemark.h"
#import "NSUserDefaults+RMSaveCustomObject.h"

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

@interface CompleteOrderViewController () <UIActionSheetDelegate, PKPaymentAuthorizationViewControllerDelegate, EnterCreditCardViewControllerDelegate, PromoCodeViewDelegate, MyAlertViewDelegate, BentoTableViewCellDelegate>
{
    BOOL _isEditingBentos;
    
    float _taxPercent;
    NSInteger _deliveryTipPercent;
    float _totalPrice;
    
    NSIndexPath *_currentIndexPath;
    
    NSInteger _clickedMinuteButtonIndex;
    
    NSString *_strPromoCode;
    NSInteger _promoDiscount;
}

@property (nonatomic, assign) IBOutlet UILabel *lblTitle;
@property (nonatomic, assign) IBOutlet UILabel *lblTitlePromo;
@property (nonatomic, assign) IBOutlet UILabel *lblTitleTax;
@property (nonatomic, assign) IBOutlet UILabel *lblTitleTip;
@property (nonatomic, assign) IBOutlet UILabel *lblTitleTotal;

@property (nonatomic, assign) IBOutlet UILabel *lblAddress;

@property (nonatomic, assign) IBOutlet UIImageView *ivCardType;
@property (nonatomic, assign) IBOutlet UILabel *lblPaymentMethod;

@property (nonatomic, assign) IBOutlet UILabel *lblPromoDiscount;
@property (nonatomic, assign) IBOutlet UILabel *lblTax;
@property (nonatomic, assign) IBOutlet UILabel *lblDeliveryTip;
@property (nonatomic, assign) IBOutlet UILabel *lblTotal;

@property (nonatomic, assign) IBOutlet UITableView *tvBentos;

@property (nonatomic, assign) IBOutlet UIButton *btnChangeAddr;
@property (nonatomic, assign) IBOutlet UIButton *btnChangeMethod;

@property (nonatomic, assign) IBOutlet UIButton *btnAddAnother;
@property (nonatomic, assign) IBOutlet UIButton *btnEdit;
@property (nonatomic, assign) IBOutlet UIButton *btnAddPromo;
@property (nonatomic, assign) IBOutlet UIButton *btnGetItNow;

@property (nonatomic, assign) IBOutlet UIView *viewList;
@property (nonatomic, assign) IBOutlet UIView *viewPromo;

@property (nonatomic, retain) NSMutableArray *aryBentos;
@property (nonatomic, retain) SVPlacemark *placeInfo;

@end

@implementation CompleteOrderViewController

- (BOOL)applePayEnabled
{
    if ([PKPaymentRequest class])
    {
        PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:APPLE_MERCHANT_ID];
        return [Stripe canSubmitPaymentRequest:paymentRequest];
    }
    
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _clickedMinuteButtonIndex = NSNotFound;
    
    UINib *cellNib = [UINib nibWithNibName:@"BentoTableViewCell" bundle:nil];
    [self.tvBentos registerNib:cellNib forCellReuseIdentifier:@"BentoCell"];
    
    self.lblTitle.text = [[AppStrings sharedInstance] getString:COMPLETE_TITLE];
    [self.btnAddAnother setTitle:[[AppStrings sharedInstance] getString:COMPLETE_TEXT_ADD_ANOTHER] forState:UIControlStateNormal];
    [self.btnEdit setTitle:[[AppStrings sharedInstance] getString:COMPLETE_TEXT_EDIT] forState:UIControlStateNormal];
    self.lblTitlePromo.text = [[AppStrings sharedInstance] getString:COMPLETE_TEXT_DISCOUNT];
    self.lblTitleTax.text = [[AppStrings sharedInstance] getString:COMPLETE_TEXT_TAX];
    self.lblTitleTip.text = [[AppStrings sharedInstance] getString:COMPLETE_TEXT_TIP];
    [self.btnAddPromo setTitle:[[AppStrings sharedInstance] getString:COMPLETE_TEXT_ADD_PROMO] forState:UIControlStateNormal];
    [self.btnGetItNow setTitle:[[AppStrings sharedInstance] getString:COMPLETE_BUTTON_FINISH] forState:UIControlStateNormal];
    
    _isEditingBentos = NO;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    _strPromoCode = [userDefaults objectForKey:KEY_PROMO_CODE];
    _promoDiscount = [userDefaults integerForKey:KEY_PROMO_DISCOUNT];
    
    _deliveryTipPercent = 15;
    _taxPercent = [[[AppStrings sharedInstance] getString:COMPLETE_TAX_PERCENT] floatValue];
    [self updatePriceLabels];
    
    _currentIndexPath = nil;
    
    self.tvBentos.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    if ([[DataManager shareDataManager] getPaymentMethod] == Payment_None)
    {
        if (![self applePayEnabled])
            [self gotoCreditScreen];
        else
            [[DataManager shareDataManager] setPaymentMethod:Payment_ApplePay];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Navigation

<<<<<<< HEAD
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
=======
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
>>>>>>> 47776439e452e2fc205c2d7569fc58f955c67495
    if ([segue.identifier isEqualToString:@"CreditCard"])
    {
        EnterCreditCardViewController *vcEnterCreditCard = segue.destinationViewController;
        vcEnterCreditCard.delegate = self;
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
    
    self.lblPaymentMethod.text = strPaymentMethod;
    [self.ivCardType setImage:[UIImage imageNamed:strImageName]];
    
<<<<<<< HEAD
    //
=======
    
>>>>>>> 47776439e452e2fc205c2d7569fc58f955c67495
    NSMutableDictionary *currentUserInfo = [[[DataManager shareDataManager] getUserInfo] mutableCopy];
    currentUserInfo[@"card"] = @{
                                 @"brand": strImageName,
                                 @"last4": strCardNumber
                                 };
<<<<<<< HEAD
    [[DataManager shareDataManager] setUserInfo:currentUserInfo paymentMethod:paymentMethod];
=======
    [[DataManager shareDataManager] setUserInfo:currentUserInfo paymentMethod:paymentMethod];// This should fix the payment issue, added paymentMethod
>>>>>>> 47776439e452e2fc205c2d7569fc58f955c67495
    
    NSLog(@"Update Payment Info, %@", currentUserInfo[@"card"]);
}

- (void)updateCardInfo
{
    NSLog(@"updated user info - %@", [[DataManager shareDataManager] getUserInfo]);
    
    PaymentMethod curPaymentMethod = [[DataManager shareDataManager] getPaymentMethod];
    if (curPaymentMethod == Payment_ApplePay)
    {
        [self.ivCardType setImage:[UIImage imageNamed:@"orderconfirm_image_applepay"]];
        self.lblPaymentMethod.text = @"Apple Pay";
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
        [self.ivCardType setImage:[UIImage imageNamed:@"orderconfirm_image_credit"]];
        self.lblPaymentMethod.text = @"";
    }
}

- (void)updatePromoView
{
//    if (self.promoDiscount == 0 && self.strPromoCode == nil)
    if (_promoDiscount == 0 && (_strPromoCode == nil || _strPromoCode.length == 0))
    {
        self.viewPromo.hidden = YES;
        self.viewList.frame = CGRectMake(self.viewList.frame.origin.x,
                                         self.viewList.frame.origin.y,
                                         self.viewList.frame.size.width,
                                         self.viewPromo.frame.origin.y + self.viewPromo.frame.size.height - self.viewList.frame.origin.y);
    }
    else
    {
        self.viewPromo.hidden = NO;
        self.viewList.frame = CGRectMake(self.viewList.frame.origin.x,
                                         self.viewList.frame.origin.y,
                                         self.viewList.frame.size.width,
                                         self.viewPromo.frame.origin.y - self.viewList.frame.origin.y);
    }
}

- (float)getTotalPrice
{
    NSInteger salePrice = [[AppStrings sharedInstance] getInteger:SALE_PRICE];
    NSInteger unitPrice = [[AppStrings sharedInstance] getInteger:ABOUT_PRICE];
    if (salePrice != 0 && salePrice < unitPrice)
        _totalPrice = self.aryBentos.count * salePrice;
    else
        _totalPrice = self.aryBentos.count * unitPrice;
    
    float deliveryTip = (int)(_totalPrice * _deliveryTipPercent) / 100.f;
    
    float tax = (int)(_totalPrice * _taxPercent) / 100.f;
    self.lblTax.text = [NSString stringWithFormat:@"$%.2f", tax];
    
    float totalPrice = _totalPrice + deliveryTip + tax - _promoDiscount;
    if (totalPrice < 0.0f)
        totalPrice = 0.0f;
    else if (totalPrice > 0 && totalPrice < 1.0f)
        totalPrice = 1.0f;
    
    return totalPrice;
}

- (void)updatePriceLabels
{
//    self.lblPromoDiscount.text = [NSString stringWithFormat:@"$%ld", (long)self.promoDiscount];
    self.lblPromoDiscount.text = [NSString stringWithFormat:@"$%ld", (long)_promoDiscount];
    self.lblDeliveryTip.text = [NSString stringWithFormat:@"%ld%%", (long)_deliveryTipPercent];
    self.lblTotal.text = [NSString stringWithFormat:@"$%.2f", [self getTotalPrice]];
}

- (void)updateUI
{
    [self updateCardInfo];
    [self updatePromoView];
    [self updatePriceLabels];
    
    //[self.tvBentos setEditing:_isEditingBentos animated:YES];
    
    NSString *strEdit = [[AppStrings sharedInstance] getString:COMPLETE_TEXT_EDIT];
    NSString *strDone = [[AppStrings sharedInstance] getString:COMPLETE_TEXT_DONE];
    
    UIColor *editColor = [UIColor colorWithRed:149.0f / 255.0f green:201.0f / 255.0f blue:97.0f / 255.0f alpha:1.0f];
    UIColor *doneColor = [UIColor colorWithRed:230.0f / 255.0f green:102.0f / 255.0f blue:53.0f / 255.0f alpha:1.0f];
    
    [self.btnEdit setTitle:(_isEditingBentos ? strDone : strEdit) forState:UIControlStateNormal];
    [self.btnEdit setTitleColor:(_isEditingBentos ? doneColor : editColor) forState:UIControlStateNormal];

    BOOL isReady = NO;
    if (self.placeInfo != nil && [[DataManager shareDataManager] getPaymentMethod] != Payment_None)
    {
        isReady = YES;
    }
    
    NSLog(@"payment - %lu, placeinfo - %@", (unsigned long)[[DataManager shareDataManager] getPaymentMethod], self.placeInfo);
    
    self.btnGetItNow.enabled = isReady;
    if (isReady)
        [self.btnGetItNow setBackgroundColor:[UIColor colorWithRed:135.0f / 255.0f green:178.0f / 255.0f blue:96.0f / 255.0f alpha:1.0f]];
    else
        [self.btnGetItNow setBackgroundColor:[UIColor colorWithRed:122.0f / 255.0f green:133.0f / 255.0f blue:146.0f / 255.0f alpha:1.0f]];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
<<<<<<< HEAD
=======

    // set array every time view appears (edit: moved from viewDidLoad)
    self.aryBentos = [[NSMutableArray alloc] init];
    for (NSInteger index = 0; index < [[BentoShop sharedInstance] getTotalBentoCount]; index++)
    {
        Bento *bento = [[BentoShop sharedInstance] getBento:index];
        if ([bento isCompleted])
            [self.aryBentos addObject:bento];
    }
    
    [self.tvBentos reloadData];
    
    NSLog(@"aryBentos in completeorder - %ld", self.aryBentos.count);
>>>>>>> 47776439e452e2fc205c2d7569fc58f955c67495
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_MENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    
    // ADDRESS
    self.lblAddress.text = @"";
    
    self.placeInfo = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"];
    if (self.placeInfo != nil)
    {
        if (self.placeInfo.subThoroughfare && self.placeInfo.thoroughfare)
            self.lblAddress.text = [NSString stringWithFormat:@"%@ %@", self.placeInfo.subThoroughfare, self.placeInfo.thoroughfare];
        else if (self.placeInfo.subThoroughfare)
            self.lblAddress.text = self.placeInfo.subThoroughfare;
        else if (self.placeInfo.thoroughfare)
            self.lblAddress.text = self.placeInfo.thoroughfare;
        else
            self.lblAddress.text = @"";
        
        [self.lblAddress setTextColor:[UIColor colorWithRed:78.f/255.f green:88.f/255.f blue:99.f/255.f alpha:1.0f]];
        [self.btnChangeAddr setTitle:@"CHANGE" forState:UIControlStateNormal];
    }
    else
    {
        self.lblAddress.text = @"Delivery Destination";
        [self.lblAddress setTextColor:[UIColor lightGrayColor]];
        [self.btnChangeAddr setTitle:[[AppStrings sharedInstance] getString:COMPLETE_TEXT_ENTER_ADDRESS] forState:UIControlStateNormal];
    }
    
    [self updateUI];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.aryBentos removeAllObjects];
    
    [super viewWillDisappear:animated];
}

- (void) onUpdatedStatus:(NSNotification *)notification
{
    if ([[BentoShop sharedInstance] isClosed] && ![[DataManager shareDataManager] isAdminUser])
        [self showSoldoutScreen:[NSNumber numberWithInt:0]];
    else if ([[BentoShop sharedInstance] isSoldOut] && ![[DataManager shareDataManager] isAdminUser])
        [self showSoldoutScreen:[NSNumber numberWithInt:1]];
    else
        [self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
}

- (void) gotoCreditScreen
{
    [self performSegueWithIdentifier:@"CreditCard" sender:nil];
}

- (void) gotoConfirmOrderScreen
{
    [self performSegueWithIdentifier:@"ConfirmOrder" sender:nil];
}

- (IBAction)onBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onChangeAddress:(id)sender
{
    NSArray *aryViewControllers = self.navigationController.viewControllers;
    
    BOOL found = NO;
    for (UIViewController *vc in aryViewControllers)
    {
        if([vc isKindOfClass:[DeliveryLocationViewController class]])
        {
            found = YES;
            ((DeliveryLocationViewController *)vc).isFromOrder = YES;
//            ((DeliveryLocationViewController *)vc).priceDiscount = self.promoDiscount;
//            ((DeliveryLocationViewController *)vc).strPromoCode = self.strPromoCode;
            [self.navigationController popToViewController:vc animated:YES];
            return;
        }
    }
    
    if (!found)
    {
        UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"DeliveryLocationViewController"];
        ((DeliveryLocationViewController *)vc).isFromOrder = YES;
//        ((DeliveryLocationViewController *)vc).priceDiscount = self.promoDiscount;
//        ((DeliveryLocationViewController *)vc).strPromoCode = self.strPromoCode;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (IBAction)onChangePayment:(id)sender
{
    if (![self applePayEnabled])
    {
        [self gotoCreditScreen];
    }
    else
    {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Payment Method" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Use Apple Pay", @"Use Credit Card", nil];
        [actionSheet showInView:self.view];
    }
}

- (IBAction)onAddAnotherBento:(id)sender
{
    [self gotoAddAnotherBentoScreen];
}

- (void)gotoAddAnotherBentoScreen
{
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    for (UIViewController *vc in viewControllers) {
        
        // dinner or lunch vc
        if ([vc isKindOfClass:[ServingDinnerViewController class]] || [vc isKindOfClass:[ServingLunchViewController class]])
        {
            // if dinner, add new bento
            if ([vc isKindOfClass:[ServingDinnerViewController class]])
            {
                [[BentoShop sharedInstance] addNewBento];
            }
           
            // go back
            [self.navigationController popToViewController:vc animated:YES];
            
            return;
        }
    }
}

- (void)showStartOverAlert
{
    NSString *strText = [[AppStrings sharedInstance] getString:ALERT_RB_TEXT];
    NSString *strConfirm = [[AppStrings sharedInstance] getString:ALERT_RB_BUTTON_CONFIRM];
    NSString *strCancel = [[AppStrings sharedInstance] getString:ALERT_RB_BUTTON_CANCEL];

    MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:strText delegate:self cancelButtonTitle:strCancel otherButtonTitle:strConfirm];
    alertView.tag = 1;
    
    [alertView showInView:self.view];
    alertView = nil;
}

- (IBAction)onEditBentos:(id)sender
{
    _isEditingBentos = !_isEditingBentos;
    
    if(!_isEditingBentos)
    {
        _clickedMinuteButtonIndex = NSNotFound;
    }

    [self updateUI];
    
    [self.tvBentos reloadData];
}

- (IBAction)onAddPromo:(id)sender
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"PromoCodeView" owner:nil options:nil];
    PromoCodeView *promoCodeView = [nib objectAtIndex:0];
    promoCodeView.delegate = self;
    
    promoCodeView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
    promoCodeView.alpha = 0.0f;
    
    [self.view addSubview:promoCodeView];
    
    [self.view bringSubviewToFront:promoCodeView];
    
    [UIView animateWithDuration:0.3f animations:^{
        
        promoCodeView.alpha = 1.0f;
        
    } completion:^(BOOL finished) {
        
    }];
    
}
/*
- (NSArray *)summaryItemsForShippingMethod:(PKShippingMethod *)shippingMethod
{
    NSString *strPrice = [NSString stringWithFormat:@"%.2f", _totalPrice];
    PKPaymentSummaryItem *shirtItem = [PKPaymentSummaryItem summaryItemWithLabel:@"Purchase of Bento" amount:[NSDecimalNumber decimalNumberWithString:strPrice]];
    NSDecimalNumber *total = [shirtItem.amount decimalNumberByAdding:shippingMethod.amount];
    PKPaymentSummaryItem *totalItem = [PKPaymentSummaryItem summaryItemWithLabel:@"Stripe Shirt Shop" amount:total];
    return @[shirtItem, shippingMethod, totalItem];
}

- (NSArray *)shippingMethods
{
    PKShippingMethod *normalItem = [PKShippingMethod summaryItemWithLabel:@"Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"20.00"]];
    normalItem.detail = @"3-5 Business Days";
    normalItem.identifier = normalItem.label;
    PKShippingMethod *expressItem =
    [PKShippingMethod summaryItemWithLabel:@"Llama California Express Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"30.00"]];
    expressItem.detail = @"Next Day";
    expressItem.identifier = expressItem.label;
    return @[normalItem, expressItem];
}
*/
- (void)processPayment
{
    NSLog(@"credit card info - %@", [[DataManager shareDataManager] getCreditCard]);
    
    PaymentMethod curPaymentMethod = [[DataManager shareDataManager] getPaymentMethod];
    if (curPaymentMethod == Payment_None)
        return;

    if (curPaymentMethod == Payment_CreditCard)
    {
        STPCard *cardInfo = [[DataManager shareDataManager] getCreditCard];
        
        
        if (cardInfo != nil) // STPCard
        {
            JGProgressHUD *loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
            loadingHUD.textLabel.text = @"Processing...";
            [loadingHUD showInView:self.view];
            
            
            
            [[STPAPIClient sharedClient] createTokenWithCard:cardInfo completion:^(STPToken *token, NSError *error) {
                if (error)
                {
                    [loadingHUD dismiss];
                    
                    MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
                    [alertView showInView:self.view];
                    alertView = nil;
                    
                }
                else
                {
                    [loadingHUD dismiss];
                    
                    // Save card information
                    [self saveCardInfo:cardInfo isApplePay:NO];
                    
                    [self createBackendChargeWithToken:token completion:nil];
                }
            }];
        }
    }
    else if (curPaymentMethod == Payment_Server)
    {
        [self createBackendChargeWithToken:nil completion:nil];
        return;
    }
    else if (curPaymentMethod == Payment_ApplePay)
    {
#ifndef DEBUG
        if (![PKPaymentAuthorizationViewController canMakePayments])
        {
            MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Error" message:@"Your iPhone cannot make in-app payments" delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
            [alertView showInView:self.view];
            alertView = nil;
            return;
        }
#endif
        
        PKPaymentRequest *request = [Stripe paymentRequestWithMerchantIdentifier:APPLE_MERCHANT_ID];
        request.countryCode = @"US";
        request.currencyCode = @"USD";
/*
        [request setRequiredShippingAddressFields:PKAddressFieldPostalAddress];
        [request setRequiredBillingAddressFields:PKAddressFieldPostalAddress];
        request.shippingMethods = [self shippingMethods];
        request.paymentSummaryItems = [self summaryItemsForShippingMethod:request.shippingMethods.firstObject];
*/
        NSString *label = @"Purchase of Bento";
        
/*
        float deliveryTip = (int)(_totalPrice * _deliveryTipPercent) / 100.f;
        float tax = (int)(_totalPrice * _taxPercent) / 100.f;
//        float totalPrice = _totalPrice + deliveryTip + tax - self.promoDiscount;
        float totalPrice = _totalPrice + deliveryTip + tax - _promoDiscount;
        if (totalPrice < 0.0f)
            totalPrice = 0.0f;
        else if (totalPrice > 0 && totalPrice < 1.0f)
            totalPrice = 1.0f;

#ifdef DEBUG
        // For test
        totalPrice = 0.0f;
#endif
*/
        float totalPrice = [self getTotalPrice];
        NSDecimalNumber *amount = (NSDecimalNumber *)[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.2f", totalPrice]];
        request.paymentSummaryItems = @[
                                        [PKPaymentSummaryItem summaryItemWithLabel:label amount:amount]
                                        ];
        
        if ([self applePayEnabled])
        {
            UIViewController *paymentController;
#ifdef DEBUG
            paymentController = [[STPTestPaymentAuthorizationViewController alloc] initWithPaymentRequest:request];
            ((STPTestPaymentAuthorizationViewController *)paymentController).delegate = self;
#else
            paymentController = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:request];
            ((PKPaymentAuthorizationViewController *)paymentController).delegate = self;
#endif
            if (paymentController != nil)
                [self presentViewController:paymentController animated:YES completion:nil];
            else
            {
                MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Error" message:@"Your iPhone cannot make in-app payments" delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
                [alertView showInView:self.view];
                alertView = nil;
                return;
            }
        }
    }
}

- (IBAction)onGetItNow:(id)sender
{
    NSString *strAPIToken = [[DataManager shareDataManager] getAPIToken];
    if (strAPIToken == nil || strAPIToken.length == 0)
    {
        [self openAccountViewController:[CompleteOrderViewController class]];
        
        return;
    }
    
    float totalPrice = [self getTotalPrice];
    if (totalPrice == 0.0f)
    {
        [self createBackendChargeWithToken:nil completion:nil];
        return;
    }

    [self processPayment];
//    [self gotoConfirmOrderScreen];
}

- (IBAction)onMinusTip:(id)sender
{
    if (_deliveryTipPercent > 0)
    {
        _deliveryTipPercent -= 5;
        
        [self updateUI];
    }
}

- (IBAction)onPlusTip:(id)sender
{
    if (_deliveryTipPercent < 30)
        _deliveryTipPercent += 5;
    
    [self updateUI];
}

- (NSString *)getAddressString:(CLPlacemark *)placeMark
{
    NSString *strAdd = nil;
    
    if (placeMark == nil)
        return strAdd;
    
    if ([placeMark.subThoroughfare length] != 0)
        strAdd = placeMark.subThoroughfare;
    
    if ([placeMark.thoroughfare length] != 0)
    {
        // strAdd -> store value of current location
        if ([strAdd length] != 0)
            strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placeMark thoroughfare]];
        else
        {
            // strAdd -> store only this value,which is not null
            strAdd = placeMark.thoroughfare;
        }
    }
    
    if ([placeMark.postalCode length] != 0)
    {
        if ([strAdd length] != 0)
            strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placeMark postalCode]];
        else
            strAdd = placeMark.postalCode;
    }
    
    if ([placeMark.locality length] != 0)
    {
        if ([strAdd length] != 0)
            strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placeMark locality]];
        else
            strAdd = placeMark.locality;
    }
    
    if ([placeMark.administrativeArea length] != 0)
    {
        if ([strAdd length] != 0)
            strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placeMark administrativeArea]];
        else
            strAdd = placeMark.administrativeArea;
    }
    
    if ([placeMark.country length] != 0)
    {
        if ([strAdd length] != 0)
            strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placeMark country]];
        else
            strAdd = placeMark.country;
    }
    
    return strAdd;
}

- (void)saveCardInfo:(STPCard *)cardInfo isApplePay:(BOOL)isApplePay
{
    NSDictionary *userInfo = [[DataManager shareDataManager] getUserInfo];
    if (userInfo == nil)
        return;

    NSString *strEmail = [userInfo objectForKey:@"email"];
    if (strEmail == nil || strEmail.length == 0)
        return;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:strEmail forKey:@"user_email"];
//    [userDefaults setObject:[cardInfo type] forKey:@"card_brand"];
//    [userDefaults setObject:[cardInfo last4] forKey:@"card_last4"];
    
    if (isApplePay)
        [userDefaults setObject:@"1" forKey:@"is_applepay"];
    else
        [userDefaults setObject:@"0" forKey:@"is_applepay"];
    
    [userDefaults synchronize];
}

#pragma mark UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.aryBentos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BentoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BentoCell" forIndexPath:indexPath];
    cell.delegate = self;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(BentoTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    Bento *curBento = [self.aryBentos objectAtIndex:indexPath.row];
    
    cell.lblBentoName.text = [NSString stringWithFormat:@"%@ Bento", [curBento getBentoName]];
    
    NSInteger salePrice = [[AppStrings sharedInstance] getInteger:SALE_PRICE];
    NSInteger unitPrice = [[AppStrings sharedInstance] getInteger:ABOUT_PRICE];
    if (salePrice != 0 && salePrice < unitPrice)
        cell.lblBentoPrice.text = [NSString stringWithFormat:@"$%ld", (long)salePrice];
    else
        cell.lblBentoPrice.text = [NSString stringWithFormat:@"$%ld", (long)unitPrice];
    
    cell.viewMain.frame = CGRectMake(0, 0, self.tvBentos.frame.size.width, 44);
    
    if(_isEditingBentos)
    {
        if(indexPath.row == _clickedMinuteButtonIndex)
        {
            [cell setRemoveState];
        }
        else
        {
            [cell setEditState];
        }
    }
    else
    {
        [cell setNormalState];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Bento *curBento = [self.aryBentos objectAtIndex:indexPath.row];
    NSLog(@"Current Bento - %@", curBento);
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    for (UIViewController *vc in viewControllers) {
        
        if ([vc isKindOfClass:[ServingDinnerViewController class]] || [vc isKindOfClass:[ServingLunchViewController class]])
        {
            if ([vc isKindOfClass:[ServingDinnerViewController class]])
            {
                [[BentoShop sharedInstance] setCurrentBento:curBento];
            }
            
            [self.navigationController popToViewController:vc animated:YES];
            
            return;
        }
    }
}

- (void) onClickedMinuteButton:(UIView *)view
{
    NSIndexPath *indexPath = [self.tvBentos indexPathForCell:(BentoTableViewCell *)view];
    
    _clickedMinuteButtonIndex = indexPath.row;
    
    [self.tvBentos reloadData];
}

- (void)onClickedRemoveButton:(UIView *)view
{
    _clickedMinuteButtonIndex = NSNotFound;
    
    NSIndexPath *indexPath = [self.tvBentos indexPathForCell:(BentoTableViewCell *)view];
    
    _currentIndexPath = indexPath;
    
    if (self.aryBentos.count > 1)
    {
        [self removeBento];
    }
    else
    {
        [self showStartOverAlert];
    }
}

- (void)removeBento
{
    Bento *bento = [self.aryBentos objectAtIndex:_currentIndexPath.row];
    [[BentoShop sharedInstance] removeBento:bento];
    [self.aryBentos removeObjectAtIndex:_currentIndexPath.row];
    [self.tvBentos reloadData];
    _currentIndexPath = nil;
    [self updateUI];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[AppStrings sharedInstance] getString:COMPLETE_TEXT_REMOVE];
}

#pragma mark PKPaymentAuthorizationViewControllerDelegate

- (NSDictionary *)buildRequest:(NSString *)stripeToken
{
    NSMutableDictionary *request = [[NSMutableDictionary alloc] init];
    
    // Bento Array
    NSMutableArray *aryBentos = [[NSMutableArray alloc] init];
    for (NSInteger index = 0; index < self.aryBentos.count; index++)
    {
        Bento *bento = [self.aryBentos objectAtIndex:index];
        
        NSMutableDictionary *bentoInfo = [[NSMutableDictionary alloc] init];
        [bentoInfo setObject:@"CustomerBentoBox" forKey:@"item_type"];
        
        NSMutableArray *dishArray = [[NSMutableArray alloc] init];
        
        NSInteger dishIndex = [bento getMainDish];
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getMainDish:dishIndex];
        NSString *strDishName = [dishInfo objectForKey:@"name"];
        NSDictionary *dicDish = @{ @"id" : [NSString stringWithFormat:@"%ld", (long)dishIndex], @"type" : @"main", @"name" : strDishName };
        [dishArray addObject:dicDish];
        
        dishIndex = [bento getSideDish1];
        dishInfo = [[BentoShop sharedInstance] getSideDish:dishIndex];
        strDishName = [dishInfo objectForKey:@"name"];
        dicDish = @{ @"id" : [NSString stringWithFormat:@"%ld", (long)dishIndex], @"type" : @"side1", @"name" : strDishName };
        [dishArray addObject:dicDish];
        
        dishIndex = [bento getSideDish2];
        dishInfo = [[BentoShop sharedInstance] getSideDish:dishIndex];
        strDishName = [dishInfo objectForKey:@"name"];
        dicDish = @{ @"id" : [NSString stringWithFormat:@"%ld", (long)dishIndex], @"type" : @"side2", @"name" : strDishName };
        [dishArray addObject:dicDish];
        
        dishIndex = [bento getSideDish3];
        dishInfo = [[BentoShop sharedInstance] getSideDish:dishIndex];
        strDishName = [dishInfo objectForKey:@"name"];
        dicDish = @{ @"id" : [NSString stringWithFormat:@"%ld", (long)dishIndex], @"type" : @"side3", @"name" : strDishName };
        [dishArray addObject:dicDish];
        
        dishIndex = [bento getSideDish4];
        dishInfo = [[BentoShop sharedInstance] getSideDish:dishIndex];
        strDishName = [dishInfo objectForKey:@"name"];
        dicDish = @{ @"id" : [NSString stringWithFormat:@"%ld", (long)dishIndex], @"type" : @"side4", @"name" : strDishName };
        [dishArray addObject:dicDish];
        
        [bentoInfo setObject:dishArray forKey:@"items"];
        
        [aryBentos addObject:bentoInfo];
    }
    
    [request setObject:aryBentos forKey:@"OrderItems"];
    
    // Order details
    NSMutableDictionary *detailInfo = [[NSMutableDictionary alloc] init];
    
    // - Address
    NSMutableDictionary *addressInfo = [[NSMutableDictionary alloc] init];
    NSLog(@"%@", self.placeInfo);
    
    NSString *strNumber = self.placeInfo.subThoroughfare;
    if (strNumber == nil)
        strNumber = @"";
    [addressInfo setObject:strNumber forKey:@"number"];

    NSString *strStreet = self.placeInfo.thoroughfare;
    if (strStreet == nil)
        strStreet = @"";
    [addressInfo setObject:strStreet forKey:@"street"];
    
    [addressInfo setObject:self.placeInfo.locality forKey:@"city"];
    [addressInfo setObject:self.placeInfo.administrativeAreaCode forKey:@"state"];
    [addressInfo setObject:self.placeInfo.postalCode forKey:@"zip"];
    [detailInfo setObject:addressInfo forKey:@"address"];
    
    // - Coordinates
    NSMutableDictionary *coordInfo = [[NSMutableDictionary alloc] init];
    [coordInfo setObject:[NSString stringWithFormat:@"%.6f", self.placeInfo.location.coordinate.latitude] forKey:@"lat"];
    [coordInfo setObject:[NSString stringWithFormat:@"%.6f", self.placeInfo.location.coordinate.longitude] forKey:@"long"];
    
    [detailInfo setObject:coordInfo forKey:@"coords"];
    
    // - Tax
    float tax = (int)(_totalPrice * _taxPercent) / 100.f;
    [detailInfo setObject:[NSString stringWithFormat:@"%ld", (long)(tax * 100)] forKey:@"tax_cents"];
    
    // - Tip
    float deliveryTip = (int)(_totalPrice * _deliveryTipPercent) / 100.f;
//    float totalPrice = _totalPrice + tax + deliveryTip - self.promoDiscount;
/*
    float totalPrice = _totalPrice + tax + deliveryTip - _promoDiscount;
    if (totalPrice < 0.0f)
        totalPrice = 0.0f;
    else if (totalPrice > 0 && totalPrice < 1.0f)
        totalPrice = 1.0f;
*/
    float totalPrice = [self getTotalPrice];
    [detailInfo setObject:[NSString stringWithFormat:@"%ld", (long)(deliveryTip * 100)] forKey:@"tip_cents"];
    
    // - Total
    [detailInfo setObject:[NSString stringWithFormat:@"%ld", (long)(totalPrice * 100)] forKey:@"total_cents"];
    
    [request setObject:detailInfo forKey:@"OrderDetails"];
    
    // Stripe
    NSDictionary *stripeInfo = nil;
    PaymentMethod curPaymentMethod = [[DataManager shareDataManager] getPaymentMethod];
    
    if ([self getTotalPrice] == 0 || curPaymentMethod == Payment_Server)
    {
        stripeInfo = @{ @"stripeToken" : @"NULL" };
    }
    else
    {
        if (stripeToken != nil)
            stripeInfo = @{ @"stripeToken" : stripeToken };
    }
    
    [request setObject:stripeInfo forKey:@"Stripe"];
    // Stripe token
    
    // PromoCode
    NSString *strPromoCode = @"";
//    if (self.strPromoCode != nil && self.strPromoCode.length > 0)
//        strPromoCode = self.strPromoCode;
    if (_strPromoCode != nil && _strPromoCode.length > 0)
        strPromoCode = _strPromoCode;
    
    [request setObject:strPromoCode forKey:@"CouponCode"];
    
    return request;
}

- (void)createBackendChargeWithToken:(STPToken *)token completion:(void (^)(PKPaymentAuthorizationStatus))completion
{
    NSLog(@"the token - %@", token.tokenId);
    
    if (token.tokenId == nil || token.tokenId.length == 0)
    {
        if ([self getTotalPrice] > 0 && [[DataManager shareDataManager] getPaymentMethod] != Payment_Server)
            return;
    }
    
    NSDictionary *request = nil;
    if (token.tokenId != nil)
        request = [self buildRequest:token.tokenId];
    else if ([self getTotalPrice] == 0.0f || [[DataManager shareDataManager] getPaymentMethod] == Payment_Server)
        request = [self buildRequest:nil];
    
    NSDictionary *dicRequest = @{@"data" : [request jsonEncodedKeyValueString]};
    WebManager *webManager = [[WebManager alloc] init];
    
    JGProgressHUD *loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Purchasing...";
    [loadingHUD showInView:self.view];
    
    NSString *strRequest = [NSString stringWithFormat:@"%@/order?api_token=%@", SERVER_URL, [[DataManager shareDataManager] getAPIToken]];
    
    NSLog(@"order URL - %@", strRequest);
    
    [webManager AsyncProcess:strRequest method:POST parameters:dicRequest success:^(MKNetworkOperation *networkOperation) {
        NSLog(@"order JSON - %@", dicRequest);
        
        [loadingHUD dismiss];
        
        if (completion)
            completion(PKPaymentAuthorizationStatusSuccess);
        
        for (Bento *bento in self.aryBentos)
            [[BentoShop sharedInstance] removeBento:bento];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:@"" forKey:KEY_PROMO_CODE];
        [userDefaults setInteger:0 forKey:KEY_PROMO_DISCOUNT];
        
        [self gotoConfirmOrderScreen];
        
    } failure:^(MKNetworkOperation *errorOp, NSError *error) {
        [loadingHUD dismiss];
        
        if (completion)
            completion(PKPaymentAuthorizationStatusFailure);
        
        // Add by Han 2015/03/11 for check Quantity.
        if (error.code == 410) // The inventory is not available.
        {
            id menuStatus = [errorOp.responseJSON objectForKey:@"MenuStatus"];
            if ([menuStatus isKindOfClass:[NSArray class]])
                [[BentoShop sharedInstance] setStatus:menuStatus];
        }
        
        NSString *strMessage = [[DataManager shareDataManager] getErrorMessage:errorOp.responseJSON];
        if (strMessage == nil)
            strMessage = error.localizedDescription;
        
        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Error" message:strMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
        [alertView showInView:self.view];
        alertView = nil;
        
    } isJSON:NO];
}

- (void)handlePaymentAuthorizationWithCard:(STPCard *)card
                                   completion:(void (^)(PKPaymentAuthorizationStatus))completion
{
    [[STPAPIClient sharedClient] createTokenWithCard:card completion:^(STPToken *token, NSError *error) {
        if (error)
        {
            MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
            [alertView showInView:self.view];
            alertView = nil;
            
            completion(PKPaymentAuthorizationStatusFailure);
            return;
        }
        
        // Save card information
        [self saveCardInfo:card isApplePay:YES];
        [self createBackendChargeWithToken:token completion:completion];
    }];
}

- (void)handlePaymentAuthorizationWithPayment:(PKPayment *)payment
                                   completion:(void (^)(PKPaymentAuthorizationStatus))completion
{
    [[STPAPIClient sharedClient] createTokenWithPayment:payment completion:^(STPToken *token, NSError *error) {
        if (error)
        {
            MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
            [alertView showInView:self.view];
            alertView = nil;
            
            completion(PKPaymentAuthorizationStatusFailure);
            return;
        }
        
        // Save card information
        [self saveCardInfo:token.card isApplePay:YES];
        [self createBackendChargeWithToken:token completion:completion];
    }];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))completion
{
#ifdef DEBUG
    if (payment.stp_testCardNumber)
    {
        STPCard *card = [STPCard new];
        card.number = payment.stp_testCardNumber;
        card.expMonth = 12;
        card.expYear = 2020;
        card.cvc = @"123";
        [self handlePaymentAuthorizationWithCard:card completion:completion];
    }
#else
    [self handlePaymentAuthorizationWithPayment:payment completion:completion];
#endif//DEBUG
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark EnterCreditCardViewControllerDelegate

- (void)setCardInfo:(STPCard *)cardInfo
{
    [[DataManager shareDataManager] setCreditCard:cardInfo];
    
    NSLog(@"cardInfo - %@", cardInfo);

    [self updateUI];
}

#pragma mark PromoCodeViewDelegate

- (void)setDiscound:(NSInteger)priceDiscount strCouponCode:(NSString *)strCouponCode
{
//    self.strPromoCode = strCouponCode;
//    self.promoDiscount = priceDiscount;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:strCouponCode forKey:KEY_PROMO_CODE];
    [userDefaults setInteger:priceDiscount forKey:KEY_PROMO_DISCOUNT];
    
    _strPromoCode = strCouponCode;
    _promoDiscount = priceDiscount;
    
    [self updateUI];
}

#pragma mark MyAlertViewDelegate

- (void)alertView:(MyAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1)
    {
        if (buttonIndex == 0)
        {
            _currentIndexPath = nil;
        }
        else if (buttonIndex == 1)
        {
            [self removeBento];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        [[DataManager shareDataManager] setCreditCard:nil];
        [[DataManager shareDataManager] setPaymentMethod:Payment_ApplePay];
        [self updateUI];
    }
    else if (buttonIndex == 1)
    {
        [self performSelector:@selector(gotoCreditScreen) withObject:nil afterDelay:0.3f];
    }
}

@end
