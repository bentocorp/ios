//
//  CompleteOrderViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "CompleteOrderViewController.h"

#import "FaqViewController.h"
#import "MyBentoViewController.h"
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

#define APPLE_MERCHANT_ID @"merchant.com.bento"

@interface CompleteOrderViewController () <UIActionSheetDelegate, PKPaymentAuthorizationViewControllerDelegate, EnterCreditCardViewControllerDelegate, PromoCodeViewDelegate, MyAlertViewDelegate, BentoTableViewCellDelegate>
{
    BOOL _isEditingBentos;
    BOOL _isApplePayEnabled;
    
    // Payment
    BOOL _hasCreditCard;
    
    // Promo Code
    NSInteger _promoDiscount;
    float _taxPercent;
    NSInteger _deliveryTipPercent;
    float _totalPrice;
    
    NSIndexPath *_currentIndexPath;
    
    NSInteger _clickedMinuteButtonIndex;
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
    // Do any additional setup after loading the view.
    
    _clickedMinuteButtonIndex = NSNotFound;
    
    UINib *cellNib = [UINib nibWithNibName:@"BentoTableViewCell" bundle:nil];
    [self.tvBentos registerNib:cellNib forCellReuseIdentifier:@"BentoCell"];
    
    self.aryBentos = [[NSMutableArray alloc] init];
    for (NSInteger index = 0; index < [[BentoShop sharedInstance] getTotalBentoCount]; index++)
    {
        Bento *bento = [[BentoShop sharedInstance] getBento:index];
        if ([bento isCompleted])
            [self.aryBentos addObject:bento];
    }
    
    self.lblTitle.text = [[AppStrings sharedInstance] getString:COMPLETE_TITLE];
    [self.btnAddAnother setTitle:[[AppStrings sharedInstance] getString:COMPLETE_TEXT_ADD_ANOTHER] forState:UIControlStateNormal];
    [self.btnEdit setTitle:[[AppStrings sharedInstance] getString:COMPLETE_TEXT_EDIT] forState:UIControlStateNormal];
    self.lblTitlePromo.text = [[AppStrings sharedInstance] getString:COMPLETE_TEXT_DISCOUNT];
    self.lblTitleTax.text = [[AppStrings sharedInstance] getString:COMPLETE_TEXT_TAX];
    self.lblTitleTip.text = [[AppStrings sharedInstance] getString:COMPLETE_TEXT_TIP];
    [self.btnAddPromo setTitle:[[AppStrings sharedInstance] getString:COMPLETE_TEXT_ADD_PROMO] forState:UIControlStateNormal];
    [self.btnGetItNow setTitle:[[AppStrings sharedInstance] getString:COMPLETE_BUTTON_FINISH] forState:UIControlStateNormal];
    
    _isEditingBentos = NO;
    
    _hasCreditCard = NO;
    if ([[DataManager shareDataManager] hasCreditCard])
        _hasCreditCard = YES;
    
    _promoDiscount = 0;
    
    _deliveryTipPercent = 15;
    _taxPercent = [[[AppStrings sharedInstance] getString:COMPLETE_TAX_PERCENT] floatValue];
    [self updatePriceLabels];
    
    _currentIndexPath = nil;
    
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
    
    self.tvBentos.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    PKPaymentRequest *request = [Stripe paymentRequestWithMerchantIdentifier:@"merchant.com.bento"];
    
    // Check apple pay is available on the iPhone.
    NSString *label = @"Checking if Apple Pay is available";
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:@"0.01"];
    request.paymentSummaryItems = @[
                                    [PKPaymentSummaryItem summaryItemWithLabel:label amount:amount]
                                    ];
    
    _isApplePayEnabled = [self applePayEnabled];
    if (!_isApplePayEnabled && !_hasCreditCard && [[DataManager shareDataManager] getCreditCard] == nil)
        [self gotoCreditScreen];
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
    if ([segue.identifier isEqualToString:@"CreditCard"])
    {
        EnterCreditCardViewController *vcEnterCreditCard = segue.destinationViewController;
        vcEnterCreditCard.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"Faq"])
    {
        FaqViewController *vc = segue.destinationViewController;
        vc.contentType = CONTENT_FAQ;
    }
}

- (void)updateCardInfo
{
    if (_hasCreditCard && [[DataManager shareDataManager] getCreditCard] == nil)
    {
        NSDictionary *userInfo = [[DataManager shareDataManager] getUserInfo];
        NSDictionary *cardInfo = [userInfo objectForKey:@"card"];
        NSString *strCardType = [[cardInfo objectForKey:@"brand"] lowercaseString];
        NSString *strCardNumber = [cardInfo objectForKey:@"last4"];
        
        self.lblPaymentMethod.text = @"";
        
        if ([strCardType isEqualToString:@"applepay"])
        {
            [self.ivCardType setImage:[UIImage imageNamed:@"orderconfirm_image_applepay"]];
            self.lblPaymentMethod.text = @"Apple Pay";
        }
        else if ([strCardType isEqualToString:@"amex"])
        {
            [self.ivCardType setImage:[UIImage imageNamed:@"amex"]];
            self.lblPaymentMethod.text = strCardNumber;
        }
        else if ([strCardType isEqualToString:@"diners"])
        {
            [self.ivCardType setImage:[UIImage imageNamed:@"diners"]];
            self.lblPaymentMethod.text = strCardNumber;
        }
        else if ([strCardType isEqualToString:@"discover"])
        {
            [self.ivCardType setImage:[UIImage imageNamed:@"discover"]];
            self.lblPaymentMethod.text = strCardNumber;
        }
        else if ([strCardType isEqualToString:@"jcb"])
        {
            [self.ivCardType setImage:[UIImage imageNamed:@"jcb"]];
            self.lblPaymentMethod.text = strCardNumber;
        }
        else if ([strCardType isEqualToString:@"mastercard"])
        {
            [self.ivCardType setImage:[UIImage imageNamed:@"mastercard"]];
            self.lblPaymentMethod.text = strCardNumber;
        }
        else if ([strCardType isEqualToString:@"visa"])
        {
            [self.ivCardType setImage:[UIImage imageNamed:@"visa"]];
            self.lblPaymentMethod.text = strCardNumber;
        }
    }
    else if ([[DataManager shareDataManager] getCreditCard] != nil)
    {
        STPCard *cardInfo = [[DataManager shareDataManager] getCreditCard];
        PTKCardNumber *cardNumber = [PTKCardNumber cardNumberWithString:cardInfo.number];
        PTKCardType cardType = [cardNumber cardType];
        NSString *cardTypeName = @"placeholder";
        self.lblPaymentMethod.text = @"";
        
        switch (cardType) {
            case PTKCardTypeAmex:
                cardTypeName = @"amex";
                self.lblPaymentMethod.text = cardNumber.last4;
                break;
            case PTKCardTypeDinersClub:
                cardTypeName = @"diners";
                self.lblPaymentMethod.text = cardNumber.last4;
                break;
            case PTKCardTypeDiscover:
                cardTypeName = @"discover";
                self.lblPaymentMethod.text = cardNumber.last4;
                break;
            case PTKCardTypeJCB:
                cardTypeName = @"jcb";
                self.lblPaymentMethod.text = cardNumber.last4;
                break;
            case PTKCardTypeMasterCard:
                cardTypeName = @"mastercard";
                self.lblPaymentMethod.text = cardNumber.last4;
                break;
            case PTKCardTypeVisa:
                cardTypeName = @"visa";
                self.lblPaymentMethod.text = cardNumber.last4;
                break;
            default:
                break;
        }
        
        [self.ivCardType setImage:[UIImage imageNamed:cardTypeName]];
    }
    else
    {
        if (_isApplePayEnabled)
        {
            [self.ivCardType setImage:[UIImage imageNamed:@"orderconfirm_image_applepay"]];
            self.lblPaymentMethod.text = @"Apple Pay";
        }
        else
        {
            [self.ivCardType setImage:[UIImage imageNamed:@"orderconfirm_image_credit"]];
            self.lblPaymentMethod.text = @"";
        }
    }
}

- (void)updatePromoView
{
    if (_promoDiscount == 0)
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

- (void)updatePriceLabels
{
    self.lblPromoDiscount.text = [NSString stringWithFormat:@"$%ld", (long)_promoDiscount];
    self.lblDeliveryTip.text = [NSString stringWithFormat:@"%ld%%", (long)_deliveryTipPercent];
    
    NSInteger unitPrice = [[AppStrings sharedInstance] getInteger:ABOUT_PRICE];
    _totalPrice = self.aryBentos.count * unitPrice;
    
    float deliveryTip = (float)_totalPrice * _deliveryTipPercent / 100.f;
    
    float tax = _totalPrice * _taxPercent / 100;
    self.lblTax.text = [NSString stringWithFormat:@"$%.2f", tax];
    
    float totalPrice = _totalPrice + deliveryTip + tax - _promoDiscount;
    self.lblTotal.text = [NSString stringWithFormat:@"$%.2f", totalPrice];
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
    if (self.placeInfo != nil && (_isApplePayEnabled || _hasCreditCard || [[DataManager shareDataManager] getCreditCard] != nil))
    {
        isReady = YES;
    }
    
    self.btnGetItNow.enabled = isReady;
    if (isReady)
        [self.btnGetItNow setBackgroundColor:[UIColor colorWithRed:135.0f / 255.0f green:178.0f / 255.0f blue:96.0f / 255.0f alpha:1.0f]];
    else
        [self.btnGetItNow setBackgroundColor:[UIColor colorWithRed:122.0f / 255.0f green:133.0f / 255.0f blue:146.0f / 255.0f alpha:1.0f]];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([[DataManager shareDataManager] hasCreditCard])
        _hasCreditCard = YES;
    else
        _hasCreditCard = NO;
    
    [self updateUI];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_MENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (IBAction)onHelp:(id)sender
{
    [self performSegueWithIdentifier:@"Faq" sender:nil];
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
            [self.navigationController popToViewController:vc animated:YES];
            return;
        }
    }
    
    if(!found)
    {
        UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"DeliveryLocationViewController"];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (IBAction)onChangePayment:(id)sender
{
//    if (!_isApplePayEnabled)
//    {
        [self gotoCreditScreen];
//    }
//    else
//    {
//        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Payment Method" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Apple Pay", @"Credit ", nil];
//        [actionSheet showInView:self.view];
//    }
}

- (IBAction)onAddAnotherBento:(id)sender
{
    [self gotoAddAnotherBentoScreen];
}

- (void) gotoAddAnotherBentoScreen
{
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    for (UIViewController *vc in viewControllers) {
     
        if ([vc isKindOfClass:[MyBentoViewController class]])
        {
            [[BentoShop sharedInstance] addNewBento];
            [self.navigationController popToViewController:vc animated:YES];
            
            return;
        }
    }

    [self performSegueWithIdentifier:@"AddAnotherBento" sender:nil];
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
    STPCard *cardInfo = [[DataManager shareDataManager] getCreditCard];
    if (!_hasCreditCard && cardInfo == nil && !_isApplePayEnabled)
        return;
    
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
                
                [self createBackendChargeWithToken:token completion:nil];
            }
        }];
    }
    else if (_hasCreditCard)
    {
        [self createBackendChargeWithToken:nil completion:nil];
        return;
    }
    else if (_isApplePayEnabled)
    {
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
        float deliveryTip = (float)_totalPrice * _deliveryTipPercent / 100.f;
        float tax = _totalPrice * _taxPercent / 100;
        float totalPrice = _totalPrice + deliveryTip + tax - _promoDiscount;
        NSDecimalNumber *amount = (NSDecimalNumber *)[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.2f", totalPrice]];
        request.paymentSummaryItems = @[
                                        [PKPaymentSummaryItem summaryItemWithLabel:label amount:amount]
                                        ];
        
        if ([Stripe canSubmitPaymentRequest:request])
        {
            UIViewController *paymentController;
#ifdef DEBUG
            paymentController = [[STPTestPaymentAuthorizationViewController alloc] initWithPaymentRequest:request];
            ((STPTestPaymentAuthorizationViewController *)paymentController).delegate = self;
#else
            paymentController = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:request];
            ((PKPaymentAuthorizationViewController *)paymentController).delegate = self;
#endif
            [self presentViewController:paymentController animated:YES completion:nil];
        }
    }
}

- (IBAction)onGetItNow:(id)sender
{
    NSString *strAPIToken = [[DataManager shareDataManager] getAPIToken];
    if (strAPIToken == nil || strAPIToken.length == 0)
    {
//        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Error" message:@"Please log in first." delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
//        [alertView showInView:self.view];
//        alertView = nil;
        
        [self openAccountViewController:[CompleteOrderViewController class]];
        
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
    cell.lblBentoPrice.text = [NSString stringWithFormat:@"$%ld", (long)[[AppStrings sharedInstance] getInteger:ABOUT_PRICE]];
    
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

    NSArray *viewControllers = self.navigationController.viewControllers;
    
    for (UIViewController *vc in viewControllers) {
        
        if ([vc isKindOfClass:[MyBentoViewController class]])
        {
            [[BentoShop sharedInstance] setCurrentBento:curBento];
            [self.navigationController popToViewController:vc animated:YES];
            
            return;
        }
    }
    
    [self performSegueWithIdentifier:@"AddAnotherBento" sender:curBento];
}

- (void) onClickedMinuteButton:(UIView *)view
{
    NSIndexPath *indexPath = [self.tvBentos indexPathForCell:(BentoTableViewCell *)view];
    
    _clickedMinuteButtonIndex = indexPath.row;
    
    [self.tvBentos reloadData];
}

- (void) onClickedRemoveButton:(UIView *)view
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

//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (editingStyle == UITableViewCellEditingStyleDelete)
//    {
//        _currentIndexPath = indexPath;
//        
//        if (self.aryBentos.count > 1)
//        {
//            [self removeBento];
//        }
//        else
//        {
//            [self showStartOverAlert];
//        }
//    }
//}

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
    float tax = _totalPrice * _taxPercent / 100;
    [detailInfo setObject:[NSString stringWithFormat:@"%ld", (long)(tax * 100)] forKey:@"tax_cents"];
    
    // - Tip
    float deliveryTip = (float)_totalPrice * _deliveryTipPercent / 100.f;
    float totalPrice = _totalPrice + tax + deliveryTip - _promoDiscount;
    
    [detailInfo setObject:[NSString stringWithFormat:@"%ld", (long)(deliveryTip * 100)] forKey:@"tip_cents"];
    
    // - Total
    [detailInfo setObject:[NSString stringWithFormat:@"%ld", (long)(totalPrice * 100)] forKey:@"total_cents"];
    
    [request setObject:detailInfo forKey:@"OrderDetails"];
    
    // Stripe
    NSDictionary *stripeInfo = nil;
    if (_hasCreditCard)
        stripeInfo = @{ @"stripeToken" : @"NULL" };
    else
        stripeInfo = @{ @"stripeToken" : stripeToken };
    
    [request setObject:stripeInfo forKey:@"Stripe"];
    // Stripe token
    
    return request;
}

- (void)createBackendChargeWithToken:(STPToken *)token completion:(void (^)(PKPaymentAuthorizationStatus))completion
{
    if (!_hasCreditCard && (token.tokenId == nil || token.tokenId.length == 0))
        return;
    
    NSDictionary *request = nil;
    if (_hasCreditCard)
        request = [self buildRequest:nil];
    else
        request = [self buildRequest:token.tokenId];
    
    NSDictionary *dicRequest = @{@"data" : [request jsonEncodedKeyValueString]};
    WebManager *webManager = [[WebManager alloc] init];
    
    JGProgressHUD *loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Purchasing...";
    [loadingHUD showInView:self.view];
    
    NSString *strRequest = [NSString stringWithFormat:@"/order?api_token=%@", [[DataManager shareDataManager] getAPIToken]];
    [webManager AsyncProcess:strRequest method:POST parameters:dicRequest success:^(MKNetworkOperation *networkOperation) {
        [loadingHUD dismiss];
        
        if (completion)
            completion(PKPaymentAuthorizationStatusSuccess);
        
        for (Bento *bento in self.aryBentos)
            [[BentoShop sharedInstance] removeBento:bento];
        
        [self gotoConfirmOrderScreen];
        
    } failure:^(MKNetworkOperation *errorOp, NSError *error) {
        [loadingHUD dismiss];
        
        if (completion)
            completion(PKPaymentAuthorizationStatusFailure);
        
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

    [self updateUI];
}

#pragma mark PromoCodeViewDelegate

- (void)setDiscound:(NSInteger)priceDiscount
{
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
            [self gotoAddAnotherBentoScreen];
        }
    }
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
    }
    else if (buttonIndex == 1)
    {
        [self gotoCreditScreen];
    }
}

@end
