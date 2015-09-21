	//
//  CompleteOrderViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "CompleteOrderViewController.h"

#import "CustomBentoViewController.h"
#import "FixedBentoViewController.h"

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

#import "Mixpanel.h"
#import "Mixpanel/MPTweakInline.h"

#import <CoreLocation/CoreLocation.h>

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

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@interface CompleteOrderViewController () <UIActionSheetDelegate, PKPaymentAuthorizationViewControllerDelegate, EnterCreditCardViewControllerDelegate, PromoCodeViewDelegate, MyAlertViewDelegate, BentoTableViewCellDelegate, CLLocationManagerDelegate>

@property (nonatomic, weak) IBOutlet UILabel *lblTitle;
@property (nonatomic, weak) IBOutlet UILabel *lblTitlePromo;
@property (nonatomic, weak) IBOutlet UILabel *lblTitleTax;
@property (nonatomic, weak) IBOutlet UILabel *lblTitleTip;
@property (nonatomic, weak) IBOutlet UILabel *lblTitleTotal;

@property (nonatomic, weak) IBOutlet UILabel *lblAddress;

@property (nonatomic, weak) IBOutlet UIImageView *ivCardType;
@property (nonatomic, weak) IBOutlet UILabel *lblPaymentMethod;

@property (nonatomic, weak) IBOutlet UILabel *lblPromoDiscount;
@property (nonatomic, weak) IBOutlet UILabel *lblTax;
@property (weak, nonatomic) IBOutlet UILabel *lblDeliveryPrice;
@property (nonatomic, weak) IBOutlet UILabel *lblDeliveryTip;
@property (nonatomic, weak) IBOutlet UILabel *lblTotal;
@property (weak, nonatomic) IBOutlet UILabel *lblTotalPrevious;

@property (nonatomic, weak) IBOutlet UITableView *tvBentos;

@property (nonatomic, weak) IBOutlet UIButton *btnChangeAddr;
@property (nonatomic, weak) IBOutlet UIButton *btnChangeMethod;

@property (nonatomic, weak) IBOutlet UIButton *btnAddAnother;
@property (nonatomic, weak) IBOutlet UIButton *btnEdit;
@property (nonatomic, weak) IBOutlet UIButton *btnAddPromo;
@property (nonatomic, weak) IBOutlet UIButton *btnGetItNow;

@property (nonatomic, weak) IBOutlet UIView *viewList;
@property (nonatomic, weak) IBOutlet UIView *viewPromo;

@property (nonatomic) NSMutableArray *aryBentos;
@property (nonatomic) SVPlacemark *placeInfo;

@end

@implementation CompleteOrderViewController
{
    BOOL _isEditingBentos;
    
    float _taxPercent;
    NSInteger _deliveryTipPercent;
    float _totalPrice;
    
    NSIndexPath *_currentIndexPath;
    
    NSInteger _clickedMinuteButtonIndex;
    
    NSString *_strPromoCode;
    NSInteger _promoDiscount;
    NSString *cutText;
    
    JGProgressHUD *loadingHUD;
    
    Mixpanel *mixpanel;
    NSString *trackPaymentMethod;
    __block NSString *successOrFailure;
    
    CLLocationManager *locationManager;
    CLLocationCoordinate2D coordinate;
    
    // idempotent token
    NSString *uuid;
    
    float deliveryPrice;
    
    BOOL allowCommitOnKeep;
}

- (BOOL)applePayEnabled
{
    if ([PKPaymentRequest class]) {
        PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:APPLE_MERCHANT_ID];
        return [Stripe canSubmitPaymentRequest:paymentRequest];
    }
    
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    allowCommitOnKeep = YES;
    
    // Mixpanel track for Placed An Order
    mixpanel = [Mixpanel sharedInstance];
    
    _clickedMinuteButtonIndex = NSNotFound;
    
    UINib *cellNib = [UINib nibWithNibName:@"BentoTableViewCell" bundle:nil];
    [self.tvBentos registerNib:cellNib forCellReuseIdentifier:@"BentoCell"];
    
    self.lblTitle.text = [[AppStrings sharedInstance] getString:COMPLETE_TITLE];
    [self.btnAddAnother setTitle:[[AppStrings sharedInstance] getString:COMPLETE_TEXT_ADD_ANOTHER] forState:UIControlStateNormal];
    [self.btnEdit setTitle:[[AppStrings sharedInstance] getString:COMPLETE_TEXT_EDIT] forState:UIControlStateNormal];
    self.lblTitlePromo.text = [[AppStrings sharedInstance] getString:COMPLETE_TEXT_DISCOUNT];
    self.lblTitleTax.text = [[AppStrings sharedInstance] getString:COMPLETE_TEXT_TAX];
    self.lblTitleTip.text = [[AppStrings sharedInstance] getString:COMPLETE_TEXT_TIP];
    
    [self.btnGetItNow setTitle:[[AppStrings sharedInstance] getString:COMPLETE_BUTTON_FINISH] forState:UIControlStateNormal];
    
    _isEditingBentos = NO;
    
    self.lblTotalPrevious.hidden = YES;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    _strPromoCode = [userDefaults objectForKey:KEY_PROMO_CODE];
    _promoDiscount = [userDefaults integerForKey:KEY_PROMO_DISCOUNT];
    
    _deliveryTipPercent = 15;
    _taxPercent = [[[AppStrings sharedInstance] getString:COMPLETE_TAX_PERCENT] floatValue];
    [self updatePriceLabels];
    
    _currentIndexPath = nil;
    
    self.tvBentos.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    if ([[DataManager shareDataManager] getPaymentMethod] == Payment_None) {
        if (![self applePayEnabled]) {
            [self gotoCreditScreen];
        }
        else {
            [[DataManager shareDataManager] setPaymentMethod:Payment_ApplePay];
            
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"Viewed Summary Screen For First Time - Apple Pay Enabled"] == nil) {
                [[Mixpanel sharedInstance] track:@"Viewed Summary Screen For First Time - Apple Pay Enabled"];
                
                [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"Viewed Summary Screen For First Time - Apple Pay Enabled"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
    }
}

#pragma mark - Geofence

- (void)initializeRegionMonitoring
{
    // Initialize location manager.
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = 99999; // only update if moved 99999 meters
    
    if(![CLLocationManager locationServicesEnabled]) {
        // You need to enable Location Services
    }
    
    if(![CLLocationManager isMonitoringAvailableForClass:[CLRegion class]]) {
        // Region monitoring is not available for this Class
    }
    
    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
        // You need to authorize Location Services for the APP
        [self commitOnGetItNow];
        
        return;
    }
    
    CLRegion *region = [self getRegion];
    [locationManager startMonitoringForRegion:region];
    [locationManager startUpdatingLocation];
}

- (CLRegion *)getRegion
{
    NSString *identifier = @"Saved Address";
    
    CLLocationDegrees latitude = [[[NSUserDefaults standardUserDefaults] objectForKey:@"savedLatitude"] doubleValue];
    CLLocationDegrees longitude = [[[NSUserDefaults standardUserDefaults] objectForKey:@"savedLongitude"] doubleValue];
    CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(latitude, longitude);
    
    CLLocationDistance regionRadius;
    NSString *geofenceOrderRadiusMeters = [[BentoShop sharedInstance] getGeofenceRadius];
    
    if (geofenceOrderRadiusMeters != nil) {
        regionRadius = [geofenceOrderRadiusMeters integerValue];
    }
    else {
        regionRadius = 100;
    }
    
    if (regionRadius > locationManager.maximumRegionMonitoringDistance) {
        regionRadius = locationManager.maximumRegionMonitoringDistance;
    }
    
    CLRegion * region = [[CLCircularRegion alloc] initWithCenter:centerCoordinate radius:regionRadius identifier:identifier];
    
    return region;
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"Did Exit Region!!!");
    
    MyAlertView *outsideRegionAlert = [[MyAlertView alloc] initWithTitle:@"It looks like you're not at this address:"
                                                                 message:self.lblAddress.text
                                                                delegate:self
                                                       cancelButtonTitle:@"Keep"
                                                        otherButtonTitle:@"Change"];
    outsideRegionAlert.tag = 911;
    
    [outsideRegionAlert showInView:self.view];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self commitOnGetItNow];
    
    // Stop Location Updation, we dont need it now
    [locationManager stopUpdatingLocation];
    locationManager = nil;
    
    [[Mixpanel sharedInstance] track:@"GPS Failed On Let's Eat"];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = locations[0];
    coordinate = location.coordinate;
    
    NSLog(@"CURRENT LAT: %f, CURRENT LONG: %f", coordinate.latitude, coordinate.longitude);
    
    NSSet * monitoredRegions = locationManager.monitoredRegions;
    
    if (monitoredRegions) {
        [monitoredRegions enumerateObjectsUsingBlock:^(CLRegion *region, BOOL *stop)
         {
             NSString *identifer = region.identifier;
             CLLocationCoordinate2D centerCoords = [(CLCircularRegion *)region center];
             CLLocationCoordinate2D currentCoords = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
             CLLocationDistance radius = [(CLCircularRegion *)region radius];
             
             NSNumber * currentLocationDistance = [self calculateDistanceInMetersBetweenCoord:currentCoords coord:centerCoords];
             
             NSLog(@"SAVED LAT: %f, SAVED LONG: %f, DISTANCE: %@", centerCoords.latitude, centerCoords.longitude, currentLocationDistance);
             
             // Outside radius
             if ([currentLocationDistance floatValue] > radius) {
                 
                 NSLog(@"Invoking didExitRegion manually for region: %@", identifer);
                 
                 //stop Monitoring Region temporarily
                 [locationManager stopMonitoringForRegion:region];
                 
                 [self locationManager:locationManager didExitRegion:region];
                 
                 //start Monitoing Region again.
//                 [locationManager startMonitoringForRegion:region];  // wtf why did i add this before?
                 
                 [[Mixpanel sharedInstance] track:@"Outside Geofence"];
             }
             // Within radius
             else {
                 [self commitOnGetItNow];
                 [[Mixpanel sharedInstance] track:@"Within Geofence"];
             }
         }];
    
        // Stop Location Updation, we dont need it now.
        [locationManager stopUpdatingLocation];
        locationManager = nil;
    }
}

- (NSNumber*)calculateDistanceInMetersBetweenCoord:(CLLocationCoordinate2D)coord1 coord:(CLLocationCoordinate2D)coord2
{
    NSInteger nRadius = 6371; // Earth's radius in Kilometers
    double latDiff = (coord2.latitude - coord1.latitude) * (M_PI/180);
    double lonDiff = (coord2.longitude - coord1.longitude) * (M_PI/180);
    double lat1InRadians = coord1.latitude * (M_PI/180);
    double lat2InRadians = coord2.latitude * (M_PI/180);
    double nA = pow ( sin(latDiff/2), 2 ) + cos(lat1InRadians) * cos(lat2InRadians) * pow ( sin(lonDiff/2), 2 );
    double nC = 2 * atan2( sqrt(nA), sqrt( 1 - nA ));
    double nD = nRadius * nC;
    // convert to meters
    return @(nD*1000);
}

// getter
- (CLLocationCoordinate2D )getCurrentLocation
{
#if (TARGET_IPHONE_SIMULATOR)
    CLLocation *location = [[CLLocation alloc] initWithLatitude:33.571895f longitude:-117.7379837036132f];
    return location.coordinate;
#endif
    
    return coordinate;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    uuid = [[NSUUID UUID] UUIDString];
    NSLog(@"UUID = %@", uuid);
    
    self.aryBentos = [[NSMutableArray alloc] init];
    for (NSInteger index = 0; index < [[BentoShop sharedInstance] getTotalBentoCount]; index++) {
        Bento *bento = [[BentoShop sharedInstance] getBento:index];
        if ([bento isCompleted])
            [self.aryBentos addObject:bento];
    }
    NSLog(@"aryBentos checkout - %@", self.aryBentos);
    
    [self.tvBentos reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_MENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCurrentMode) name:@"checkModeOrDateChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCurrentMode) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimerOnViewedScreen) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endTimerOnViewedScreen) name:@"enteringBackground" object:nil];
    
    // ADDRESS
    self.lblAddress.text = @"";
    
    self.placeInfo = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"];
    if (self.placeInfo != nil) {
        
        if (self.placeInfo.subThoroughfare && self.placeInfo.thoroughfare) {
            self.lblAddress.text = [NSString stringWithFormat:@"%@ %@", self.placeInfo.subThoroughfare, self.placeInfo.thoroughfare];
        }
        else if (self.placeInfo.subThoroughfare) {
            self.lblAddress.text = self.placeInfo.subThoroughfare;
        }
        else if (self.placeInfo.thoroughfare) {
            self.lblAddress.text = self.placeInfo.thoroughfare;
        }
        else {
            self.lblAddress.text = @"";
        }
        
        [self.lblAddress setTextColor:[UIColor colorWithRed:78.f/255.f green:88.f/255.f blue:99.f/255.f alpha:1.0f]];
        [self.btnChangeAddr setTitle:@"CHANGE" forState:UIControlStateNormal];
    }
    else {
        self.lblAddress.text = @"Delivery Destination";
        [self.lblAddress setTextColor:[UIColor lightGrayColor]];
        [self.btnChangeAddr setTitle:[[AppStrings sharedInstance] getString:COMPLETE_TEXT_ENTER_ADDRESS] forState:UIControlStateNormal];
    }
    
    [self updateUI];
    
    [self startTimerOnViewedScreen];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.aryBentos removeAllObjects];
    
    [super viewWillDisappear:animated];
    
    [self endTimerOnViewedScreen];
}

#pragma mark Duration on screen
- (void)startTimerOnViewedScreen
{
    [[Mixpanel sharedInstance] timeEvent:@"Viewed Summary Screen"];
}

- (void)endTimerOnViewedScreen
{
    [[Mixpanel sharedInstance] track:@"Viewed Summary Screen"];
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

- (void)checkCurrentMode
{
    if ([[BentoShop sharedInstance] didModeOrDateChange])
    {
        [(UINavigationController *)self.presentingViewController popToRootViewControllerAnimated:NO];
        [self dismissViewControllerAnimated:YES completion:nil];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (NSString *)getCurrentTime
{
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *currentTime = [dateFormatter stringFromDate:today];
    
    return currentTime;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
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
    
    /* should i add expirtion date to card into as well? */
    
    NSMutableDictionary *currentUserInfo = [[[DataManager shareDataManager] getUserInfo] mutableCopy];
    currentUserInfo[@"card"] = @{
                                 @"brand": strImageName,
                                 @"last4": strCardNumber
                                 };
    [[DataManager shareDataManager] setUserInfo:currentUserInfo paymentMethod:paymentMethod]; // This should fix the payment issue, added paymentMethod
    
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
    
    if (MPTweakValue(@"$0.00 Delivery Fee", NO)) {
        // test
        deliveryPrice = 0.00;
    }
    else {
        // original
        deliveryPrice = [[AppStrings sharedInstance] getFloat:DELIVERY_FEE];
    }
    
    // Meal (_totalPrice)
    if (salePrice != 0 && salePrice < unitPrice) {
        _totalPrice = self.aryBentos.count * salePrice;
    }
    else {
        _totalPrice = self.aryBentos.count * unitPrice;
    }
    
    // Meal * % = Tip
    float deliveryTip = (_totalPrice * _deliveryTipPercent) / 100.f;
    
    // Add Delivery Fee
    _totalPrice += deliveryPrice;
    
    // (Meal + deliveryPrice) - Promo) * 0.875(tax) = Tax
    float tax;
    if (_promoDiscount <= _totalPrice) {
        tax = [self roundToNearestHundredth:((_totalPrice - _promoDiscount) * _taxPercent) / 100.f];
    }
    else {
        tax = 0; // if Promo is greater than Meal
    }
    
    // Meal + Tax + Tip
    float subTotal = _totalPrice + tax + deliveryTip; // tip is subtracted from promo code, once used up, it starts charging user's card
    
    // Grand Total
    float totalPrice;
    if (subTotal - _promoDiscount >= 0) { // ie. subtotal(13.80) - promo(5)
        totalPrice = subTotal - _promoDiscount;
    }
    else {
        totalPrice = 0; // if Promo hasn't been used up yet ie. subtotal(13.80) - promo(85),
    }
    
    // show old price
    if (_promoDiscount > 0) {
        self.lblTotalPrevious.hidden = NO;
        cutText = [NSString stringWithFormat:@"$%.2f", (_totalPrice + (_totalPrice * (_taxPercent/100.f)) + deliveryTip)];
    }
    
    NSLog(@"PROMO CREDIT LEFT: %f", _promoDiscount - subTotal);
    NSLog(@"SUB TOTAL: %f", subTotal);
    NSLog(@"GRAND TOTAL: %f", totalPrice);
    
    self.lblTax.text = [NSString stringWithFormat:@"$%.2f", tax];
    
    return totalPrice;
}

// works for x.xxxxxxxx
- (float)roundToNearestHundredth:(float)originalNumber
{
    originalNumber += 0.005;
    originalNumber *= 100;
    originalNumber = floor(originalNumber);
    originalNumber /= 100;
    
    return originalNumber;
}

- (void)updatePriceLabels
{
    self.lblPromoDiscount.text = [NSString stringWithFormat:@"$%ld", (long)_promoDiscount];
    self.lblDeliveryTip.text = [NSString stringWithFormat:@"%ld%%", (long)_deliveryTipPercent];
    self.lblTotal.text = [NSString stringWithFormat:@"$%.2f", [self getTotalPrice]];
    self.lblDeliveryPrice.text = [NSString stringWithFormat:@"$%.2f", deliveryPrice];
    
    // if no promo added
    if (_promoDiscount <= 0) {
        // display 'ADD PROMO'
        [self.btnAddPromo setTitleColor:[UIColor bentoBrandGreen] forState:UIControlStateNormal];
        [self.btnAddPromo setTitle:[[AppStrings sharedInstance] getString:COMPLETE_TEXT_ADD_PROMO] forState:UIControlStateNormal];
    }
    // if promo added
    else {
        [self.btnAddPromo setTitleColor:[UIColor bentoErrorTextOrange] forState:UIControlStateNormal];
        [self.btnAddPromo setTitle:@"REMOVE PROMO" forState:UIControlStateNormal];
    }
    
    // set previous price tag label
    if (cutText != nil)
    {
        NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:cutText];
        
        [titleString addAttribute:NSStrikethroughStyleAttributeName
                            value:[NSNumber numberWithInteger:NSUnderlineStyleSingle]
                            range:NSMakeRange(0, [titleString length])];
        
        self.lblTotalPrevious.attributedText = titleString;
    }
}

- (void)updateUI
{
    [self updateCardInfo];
    [self updatePromoView];
    [self updatePriceLabels];
    
    NSString *strEdit = [[AppStrings sharedInstance] getString:COMPLETE_TEXT_EDIT];
    NSString *strDone = [[AppStrings sharedInstance] getString:COMPLETE_TEXT_DONE];
    
    UIColor *editColor = [UIColor colorWithRed:149.0f / 255.0f green:201.0f / 255.0f blue:97.0f / 255.0f alpha:1.0f];
    UIColor *doneColor = [UIColor colorWithRed:230.0f / 255.0f green:102.0f / 255.0f blue:53.0f / 255.0f alpha:1.0f];
    
    [self.btnEdit setTitle:(_isEditingBentos ? strDone : strEdit) forState:UIControlStateNormal];
    [self.btnEdit setTitleColor:(_isEditingBentos ? doneColor : editColor) forState:UIControlStateNormal];

    BOOL isReady = NO;
    if (self.placeInfo != nil && [[DataManager shareDataManager] getPaymentMethod] != Payment_None) {
        isReady = YES;
    }
    
    NSLog(@"payment - %lu, placeinfo - %@", (unsigned long)[[DataManager shareDataManager] getPaymentMethod], self.placeInfo);
    
    self.btnGetItNow.enabled = isReady;
    if (isReady) {
        [self.btnGetItNow setBackgroundColor:[UIColor bentoBrandGreen]];
    }
    else {
        [self.btnGetItNow setBackgroundColor:[UIColor bentoButtonGray]];
    }
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

- (IBAction)onBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onChangeAddress:(id)sender
{
    [[Mixpanel sharedInstance] track:@"Tapped On Change - Address"];
    
    NSArray *aryViewControllers = self.navigationController.viewControllers;
    
    BOOL found = NO;
    for (UIViewController *vc in aryViewControllers)
    {
        if([vc isKindOfClass:[DeliveryLocationViewController class]])
        {
            found = YES;
            ((DeliveryLocationViewController *)vc).isFromOrder = YES;
            [self.navigationController popToViewController:vc animated:YES];
            return;
        }
    }
    
    if (!found)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        DeliveryLocationViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"DeliveryLocationViewController"];
        ((DeliveryLocationViewController *)vc).isFromOrder = YES;
        
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (IBAction)onChangePayment:(id)sender
{
    [[Mixpanel sharedInstance] track:@"Tapped On Change - Payment"];
    
    if (![self applePayEnabled])
        [self gotoCreditScreen];
    else
    {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Payment Method"
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Use Apple Pay", @"Use Credit Card", nil];
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
        if ([vc isKindOfClass:[CustomBentoViewController class]] || [vc isKindOfClass:[FixedBentoViewController class]])
        {
            // if dinner, add new bento
            if ([vc isKindOfClass:[CustomBentoViewController class]])
                [[BentoShop sharedInstance] addNewBento];
           
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
        _clickedMinuteButtonIndex = NSNotFound;

    [self updateUI];
    
    [self.tvBentos reloadData];
}

// ON 'ADD PROMO' / 'REMOVE PROMO'
- (IBAction)onAddPromo:(id)sender
{
    // no promo
    if (_promoDiscount <= 0) {
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
    else {
        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:@"Are you sure you want to remove promo?" delegate:self cancelButtonTitle:@"CANCEL" otherButtonTitle:@"OK"];
        alertView.tag = 333;
        [alertView showInView:self.view];
        alertView = nil;
    }
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
    PaymentMethod curPaymentMethod = [[DataManager shareDataManager] getPaymentMethod];
    
    if (curPaymentMethod == Payment_None)
        trackPaymentMethod = @"Payment_None";
    else if (curPaymentMethod == Payment_CreditCard)
        trackPaymentMethod = @"Payment_CreditCard";
    else if (curPaymentMethod == Payment_Server)
        trackPaymentMethod = @"Payment_Server";
    else if (curPaymentMethod == Payment_ApplePay)
        trackPaymentMethod = @"Payment_ApplePay";
    
    if (curPaymentMethod == Payment_None)
    {
        successOrFailure = @"Failure";
        [mixpanel track:@"Placed An Order" properties:@{
                                                        @"Bento Quantity": [NSString stringWithFormat:@"%lu", (unsigned long)self.aryBentos.count],
                                                        @"Payment Method": trackPaymentMethod,
                                                        @"Total Price": [NSString stringWithFormat:@"%f", [self getTotalPrice]],
                                                        @"Success/Failure": successOrFailure
                                                        }];
        return;
    }

    if (curPaymentMethod == Payment_CreditCard)
    {
        STPCard *cardInfo = [[DataManager shareDataManager] getCreditCard];

        if (cardInfo != nil) // STPCard
        {
            loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
            loadingHUD.textLabel.text = @"Processing...";
            [loadingHUD showInView:self.view];
            
            [[STPAPIClient sharedClient] createTokenWithCard:cardInfo completion:^(STPToken *token, NSError *error) {
                if (error)
                {
                    [loadingHUD dismiss];
                    
                    MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
                    [alertView showInView:self.view];
                    alertView = nil;
                    
                    successOrFailure = @"Failure";
                    [mixpanel track:@"Placed An Order" properties:@{
                                                                    @"Bento Quantity": [NSString stringWithFormat:@"%lu", (unsigned long)self.aryBentos.count],
                                                                    @"Payment Method": trackPaymentMethod,
                                                                    @"Total Price": [NSString stringWithFormat:@"%f", [self getTotalPrice]],
                                                                    @"Success/Failure": successOrFailure
                                                                    }];
                }
                else
                {
                    [loadingHUD dismiss];
                    
                    // Save card information
                    [self saveCardInfo:cardInfo isApplePay:NO];
                    
                    [self createBackendChargeWithToken:token completion:nil];
                    
                    successOrFailure = @"Success";
                    [mixpanel track:@"Placed An Order" properties:@{
                                                                    @"Bento Quantity": [NSString stringWithFormat:@"%lu", (unsigned long)self.aryBentos.count],
                                                                    @"Payment Method": trackPaymentMethod,
                                                                    @"Total Price": [NSString stringWithFormat:@"%f", [self getTotalPrice]],
                                                                    @"Success/Failure": successOrFailure
                                                                    }];
                    // track revenue
                    [mixpanel.people trackCharge:@([self getTotalPrice]) withProperties:@{
                                                                                          @"time": [self getCurrentTime]
                                                                                          }];
                }
            }];
        }
    }
    else if (curPaymentMethod == Payment_Server)
    {
        [self createBackendChargeWithToken:nil completion:nil];
        
        successOrFailure = @"Success";
        [mixpanel track:@"Placed An Order" properties:@{
                                                        @"Bento Quantity": [NSString stringWithFormat:@"%lu", (unsigned long)self.aryBentos.count],
                                                        @"Payment Method": trackPaymentMethod,
                                                        @"Total Price": [NSString stringWithFormat:@"%f", [self getTotalPrice]],
                                                        @"Success/Failure": successOrFailure
                                                        }];
        // track revenue
        [mixpanel.people trackCharge:@([self getTotalPrice]) withProperties:@{
                                                                              @"time": [self getCurrentTime]
                                                                              }];
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
            
            successOrFailure = @"Failure";
            [mixpanel track:@"Placed An Order" properties:@{
                                                            @"Bento Quantity": [NSString stringWithFormat:@"%lu", (unsigned long)self.aryBentos.count],
                                                            @"Payment Method": trackPaymentMethod,
                                                            @"Total Price": [NSString stringWithFormat:@"%f", [self getTotalPrice]],
                                                            @"Success/Failure": successOrFailure
                                                            }];
            return;
        }
#endif
        
        PKPaymentRequest *request = [Stripe paymentRequestWithMerchantIdentifier:APPLE_MERCHANT_ID];
        request.countryCode = @"US";
        request.currencyCode = @"USD";

        NSString *label = @"Purchase of Bento";
        
        float totalPrice = [self getTotalPrice];
        NSDecimalNumber *amount = (NSDecimalNumber *)[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.2f", totalPrice]];
        request.paymentSummaryItems = @[ [PKPaymentSummaryItem summaryItemWithLabel:label amount:amount] ];
        
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
            {
                // shows the gray pop up
                [self presentViewController:paymentController animated:YES completion:nil];
            
                // track in createbackendtoken
            }
            else
            {
                MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Error" message:@"Your iPhone cannot make in-app payments" delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
                [alertView showInView:self.view];
                alertView = nil;
                
                successOrFailure = @"Failure";
                [mixpanel track:@"Placed An Order" properties:@{
                                                                @"Bento Quantity": [NSString stringWithFormat:@"%lu", (unsigned long)self.aryBentos.count],
                                                                @"Payment Method": trackPaymentMethod,
                                                                @"Total Price": [NSString stringWithFormat:@"%f", [self getTotalPrice]],
                                                                @"Success/Failure": successOrFailure
                                                                }];
                return;
                
            }
        }
    }
}

- (IBAction)onGetItNow:(id)sender
{
    // set geofence
    [self initializeRegionMonitoring];
    
    [[Mixpanel sharedInstance] track:@"Tapped On Let's Eat"];
}

-(void)commitOnGetItNow
{
    self.btnGetItNow.enabled = NO;
    
    NSString *strAPIToken = [[DataManager shareDataManager] getAPIToken];
    if (strAPIToken == nil || strAPIToken.length == 0) {
        [self openAccountViewController:[CompleteOrderViewController class]];
        return;
    }
    
    float totalPrice = [self getTotalPrice];
    if (totalPrice == 0.0f) {
        [self createBackendChargeWithToken:nil completion:nil];
        return;
    }
    
    [self processPayment];
    
    NSLog(@"ON COMMIT NOW!!!");
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
    NSLog(@"didselect aryBentos - %@", self.aryBentos);
    
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    for (UIViewController *vc in viewControllers)
    {    
        if ([vc isKindOfClass:[CustomBentoViewController class]] || [vc isKindOfClass:[FixedBentoViewController class]])
        {
            if ([vc isKindOfClass:[CustomBentoViewController class]])
                [[BentoShop sharedInstance] setCurrentBento:curBento];
            
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
    
    if (self.aryBentos.count > 1) {
        [self removeBento];
    }
    else {
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
    
    [[Mixpanel sharedInstance] track:@"Removed Bento"];
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
        NSMutableDictionary *currentBentoDishes = [@{} mutableCopy]; // for mixpanel
        
        Bento *bento = [self.aryBentos objectAtIndex:index];
        
        NSMutableDictionary *bentoInfo = [[NSMutableDictionary alloc] init];
        [bentoInfo setObject:@"CustomerBentoBox" forKey:@"item_type"];
        [bentoInfo setObject:[NSString stringWithFormat:@"%ld", (long)_totalPrice] forKey:@"unit_price"];
        
        NSMutableArray *dishArray = [[NSMutableArray alloc] init];
        
        NSInteger dishIndex = [bento getMainDish];
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getMainDish:dishIndex];
        NSString *strDishName = [dishInfo objectForKey:@"name"];
        if (strDishName != nil) {
            [currentBentoDishes setObject:strDishName forKey:@"main"]; // for mixpanel
        }
        NSDictionary *dicDish = @{ @"id" : [NSString stringWithFormat:@"%ld", (long)dishIndex], @"type" : @"main", @"name" : strDishName };
        [dishArray addObject:dicDish];
        
        dishIndex = [bento getSideDish1];
        dishInfo = [[BentoShop sharedInstance] getSideDish:dishIndex];
        strDishName = [dishInfo objectForKey:@"name"];
        if (strDishName != nil) {
            [currentBentoDishes setObject:strDishName forKey:@"side1"]; // for mixpanel
        }
        dicDish = @{ @"id" : [NSString stringWithFormat:@"%ld", (long)dishIndex], @"type" : @"side1", @"name" : strDishName };
        [dishArray addObject:dicDish];
        
        dishIndex = [bento getSideDish2];
        dishInfo = [[BentoShop sharedInstance] getSideDish:dishIndex];
        strDishName = [dishInfo objectForKey:@"name"];
        if (strDishName != nil) {
            [currentBentoDishes setObject:strDishName forKey:@"side2"];
        }
        dicDish = @{ @"id" : [NSString stringWithFormat:@"%ld", (long)dishIndex], @"type" : @"side2", @"name" : strDishName };
        [dishArray addObject:dicDish];
        
        dishIndex = [bento getSideDish3];
        dishInfo = [[BentoShop sharedInstance] getSideDish:dishIndex];
        strDishName = [dishInfo objectForKey:@"name"];
        if (strDishName != nil) {
            [currentBentoDishes setObject:strDishName forKey:@"side3"];
        }
        dicDish = @{ @"id" : [NSString stringWithFormat:@"%ld", (long)dishIndex], @"type" : @"side3", @"name" : strDishName };
        [dishArray addObject:dicDish];
        
        dishIndex = [bento getSideDish4];
        dishInfo = [[BentoShop sharedInstance] getSideDish:dishIndex];
        strDishName = [dishInfo objectForKey:@"name"];
        if (strDishName != nil) {
            [currentBentoDishes setObject:strDishName forKey:@"side4"];
        }
        dicDish = @{ @"id" : [NSString stringWithFormat:@"%ld", (long)dishIndex], @"type" : @"side4", @"name" : strDishName };
        [dishArray addObject:dicDish];
        
        [bentoInfo setObject:dishArray forKey:@"items"];
        
        [aryBentos addObject:bentoInfo];
        
        NSLog(@"BENTOS: %@", currentBentoDishes);
        
        // Mixpanel
        [mixpanel track:@"Bento Requested" properties:currentBentoDishes];
    }
    
    [request setObject:aryBentos forKey:@"OrderItems"];
    
    // Order details
    NSMutableDictionary *detailInfo = [[NSMutableDictionary alloc] init];
    
    // Address
    NSMutableDictionary *addressInfo = [[NSMutableDictionary alloc] init];
    
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
    
    // Coupon Discount (cents)
    float couponDiscount = (int)_promoDiscount * 100;
    [detailInfo setObject:[NSString stringWithFormat:@"%ld", (long)couponDiscount] forKey:@"coupon_discount_cents"];
    
    // - Tax
    float tax = (int)(_totalPrice * _taxPercent) / 100.f;
    [detailInfo setObject:[NSString stringWithFormat:@"%ld", (long)(tax * 100)] forKey:@"tax_cents"];
    
    // - Tip
    float deliveryTip = (int)(_totalPrice * _deliveryTipPercent) / 100.f;

    float totalPrice = [self getTotalPrice];
    [detailInfo setObject:[NSString stringWithFormat:@"%ld", (long)(deliveryTip * 100)] forKey:@"tip_cents"];
    
    // - Total
    [detailInfo setObject:[NSString stringWithFormat:@"%ld", (long)(totalPrice * 100)] forKey:@"total_cents"];
    
    // - Delivery Price
    [detailInfo setObject:[NSString stringWithFormat:@"%.2f", deliveryPrice] forKey:@"delivery_price"];

    [request setObject:detailInfo forKey:@"OrderDetails"];
    
    // Stripe
    NSDictionary *stripeInfo = nil;
    PaymentMethod curPaymentMethod = [[DataManager shareDataManager] getPaymentMethod];
    
    if ([self getTotalPrice] == 0 || curPaymentMethod == Payment_Server) {
        stripeInfo = @{ @"stripeToken" : @"NULL" };
    }
    else {
        if (stripeToken != nil) {
            stripeInfo = @{ @"stripeToken" : stripeToken };
        }
    }
    
    [request setObject:stripeInfo forKey:@"Stripe"];
    
    // PromoCode
    NSString *strPromoCode = @"";

    if (_strPromoCode != nil && _strPromoCode.length > 0) {
        strPromoCode = _strPromoCode;
    }
    
    [request setObject:strPromoCode forKey:@"CouponCode"];
    
    // Idempotent Token
    [request setObject:uuid forKey:@"IdempotentToken"];
    
    // Platform
    [request setObject:@"iOS" forKey:@"Platform"];
    
    return request;
}

- (void)createBackendChargeWithToken:(STPToken *)token completion:(void (^)(PKPaymentAuthorizationStatus))completion
{
    if (token.tokenId == nil || token.tokenId.length == 0) {
        if ([self getTotalPrice] > 0 && [[DataManager shareDataManager] getPaymentMethod] != Payment_Server) {
            return;
        }
    }
    
    NSDictionary *request = nil;
    if (token.tokenId != nil)
        request = [self buildRequest:token.tokenId];
    else if ([self getTotalPrice] == 0.0f || [[DataManager shareDataManager] getPaymentMethod] == Payment_Server)
        request = [self buildRequest:nil];
    
    NSDictionary *dicRequest = @{@"data" : [request jsonEncodedKeyValueString]};
    WebManager *webManager = [[WebManager alloc] init];
    
    loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Purchasing...";
    [loadingHUD showInView:self.view];
    
    NSString *strRequest = [NSString stringWithFormat:@"%@/order?api_token=%@", SERVER_URL, [[DataManager shareDataManager] getAPIToken]];
    
    NSLog(@"order URL - %@", strRequest);
    NSLog(@"order JSON - %@", dicRequest[@"OrderItems"]);
    NSLog(@"ORDER ITEMS: %@", request);
    
/*-----------Track empty orders, show message, then reset app------------*/
    NSArray *orderItemsArray = request[@"OrderItems"];
    
    if (orderItemsArray.count == 0 || orderItemsArray == nil)
    {
        // bento exists
        if (self.aryBentos)
        {
            // get list of the bento names
            NSMutableArray *bentoNamesArray = [@[] mutableCopy];
            
            for (Bento *bento in self.aryBentos)
                [bentoNamesArray addObject:[bento getBentoName]];
            
            // track request and list of bento names
            [mixpanel track:@"Empty Order" properties:@{@"List of Bento Names": bentoNamesArray}];
        }
        
        // no bentos exists
        else
        {
            // track request and bentos not found
            [mixpanel track:@"Empty Order" properties:@{@"List of Bento Names": @"Not Found"}];
        }
        
        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@""
                                                            message:@"An error has occurred when processing your order. Please refresh the app and try again. Sorry for the inconvenience!"
                                                           delegate:self
                                                  cancelButtonTitle:@"Refresh App"
                                                   otherButtonTitle:nil];
        alertView.tag = 2;
        [alertView showInView:self.view];
        alertView = nil;
        
        return;
    }
/*-------------------------------------------------------------------------*/

    [webManager AsyncProcess:strRequest method:POST parameters:dicRequest success:^(MKNetworkOperation *networkOperation) {
        
        [loadingHUD dismiss];
        
        if (completion) {
            completion(PKPaymentAuthorizationStatusSuccess);
        }

        [[BentoShop sharedInstance] resetBentoArray]; // remove from temp
        [[BentoShop sharedInstance] saveBentoArray]; // save empty to persistent storage
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:@"" forKey:KEY_PROMO_CODE];
        [userDefaults setInteger:0 forKey:KEY_PROMO_DISCOUNT];
        
        [self performSegueWithIdentifier:@"ConfirmOrder" sender:nil];
        
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

/* Send card info to Stripe. Stripe returns a one-time token. */
- (void)handlePaymentAuthorizationWithCard:(STPCard *)card completion:(void (^)(PKPaymentAuthorizationStatus))completion
{
    [[STPAPIClient sharedClient] createTokenWithCard:card completion:^(STPToken *token, NSError *error) {
        if (error)
        {
            MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Error"
                                                                message:error.localizedDescription
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                       otherButtonTitle:nil];
            [alertView showInView:self.view];
            alertView = nil;
            
            completion(PKPaymentAuthorizationStatusFailure);
            
            // tracking apple pay
            if ([trackPaymentMethod isEqualToString:@"Payment_ApplePay"])
            {
                successOrFailure = @"Failure";
                [mixpanel track:@"Placed An Order" properties:@{
                                                                @"Bento Quantity": [NSString stringWithFormat:@"%lu", (unsigned long)self.aryBentos.count],
                                                                @"Payment Method": trackPaymentMethod,
                                                                @"Total Price": [NSString stringWithFormat:@"%f", [self getTotalPrice]],
                                                                @"Success/Failure": successOrFailure
                                                                }];
            }
            
            return;
        }
        else
        {
            // tracking apple pay
            if ([trackPaymentMethod isEqualToString:@"Payment_ApplePay"])
            {
                successOrFailure = @"Success";
                [mixpanel track:@"Placed An Order" properties:@{
                                                                @"Bento Quantity": [NSString stringWithFormat:@"%lu", (unsigned long)self.aryBentos.count],
                                                                @"Payment Method": trackPaymentMethod,
                                                                @"Total Price": [NSString stringWithFormat:@"%f", [self getTotalPrice]],
                                                                @"Success/Failure": successOrFailure
                                                                }];
                
                // track revenue
                [mixpanel.people trackCharge:@([self getTotalPrice]) withProperties:@{
                                                                  @"time": [self getCurrentTime]
                                                                  }];
            }
        }
        
        // Save card information
        [self saveCardInfo:card isApplePay:YES];
        
        [self createBackendChargeWithToken:token completion:completion];
    }];
}

- (void)handlePaymentAuthorizationWithPayment:(PKPayment *)payment completion:(void (^)(PKPaymentAuthorizationStatus))completion
{
    [[STPAPIClient sharedClient] createTokenWithPayment:payment completion:^(STPToken *token, NSError *error) {
        if (error)
        {
            MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
            [alertView showInView:self.view];
            alertView = nil;
            
            completion(PKPaymentAuthorizationStatusFailure);
            
            // tracking apple pay
            if ([trackPaymentMethod isEqualToString:@"Payment_ApplePay"])
            {
                successOrFailure = @"Failure";
                [mixpanel track:@"Placed An Order" properties:@{
                                                                @"Bento Quantity": [NSString stringWithFormat:@"%lu", (unsigned long)self.aryBentos.count],
                                                                @"Payment Method": trackPaymentMethod,
                                                                @"Total Price": [NSString stringWithFormat:@"%f", [self getTotalPrice]],
                                                                @"Success/Failure": successOrFailure
                                                                }];
            }
            
            return;
        }
        else
        {
            // tracking apple pay
            if ([trackPaymentMethod isEqualToString:@"Payment_ApplePay"])
            {
                successOrFailure = @"Success";
                [mixpanel track:@"Placed An Order" properties:@{
                                                                @"Bento Quantity": [NSString stringWithFormat:@"%lu", (unsigned long)self.aryBentos.count],
                                                                @"Payment Method": trackPaymentMethod,
                                                                @"Total Price": [NSString stringWithFormat:@"%f", [self getTotalPrice]],
                                                                @"Success/Failure": successOrFailure
                                                                }];
                // track revenue
                [mixpanel.people trackCharge:@([self getTotalPrice]) withProperties:@{
                                                                                      @"time": [self getCurrentTime]
                                                                                      }];
            }
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

    [self updateUI];
}

#pragma mark PromoCodeViewDelegate

- (void)setDiscound:(NSInteger)priceDiscount strCouponCode:(NSString *)strCouponCode
{
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
    // Deleting last bento response
    if (alertView.tag == 1) {
        if (buttonIndex == 0) {
            _currentIndexPath = nil;
        }
        else if (buttonIndex == 1) {
            [self removeBento];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    
    // Empty Order Response
    else if (alertView.tag == 2) {
        [[BentoShop sharedInstance] resetBentoArray];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
    // User selected Keep when confirming address
    else if (alertView.tag == 911) {
        if (buttonIndex == 0) {
            
            NSLog(@"Tapped on keep");
            
            [[Mixpanel sharedInstance] track:@"Tapped On Keep"];
            
            if (allowCommitOnKeep == YES) {
                [self commitOnGetItNow];
                
                // used to prevent multiple commitOnGetItNow's for 5 seconds after tapping keep the first time
                allowCommitOnKeep = NO;
                [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateAllowCommitOnKeep) userInfo:nil repeats:NO];
            }
        }
        else {
            [self onChangeAddress:nil];
        }
    }
    
    // Remove promo
    else if (alertView.tag == 333) {
        if (buttonIndex == 1) {
            
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:nil forKey:KEY_PROMO_CODE];
            [userDefaults setInteger:0 forKey:KEY_PROMO_DISCOUNT];
            
            _strPromoCode = nil;
            _promoDiscount = 0;
            
            self.lblTotalPrevious.hidden = YES;
            
            [self updateUI];
        }
    }
}

- (void)updateAllowCommitOnKeep
{
    allowCommitOnKeep = YES;
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [[DataManager shareDataManager] setCreditCard:nil];
        [[DataManager shareDataManager] setPaymentMethod:Payment_ApplePay];
        [self updateUI];
    }
    else if (buttonIndex == 1) {
        [self performSelector:@selector(gotoCreditScreen) withObject:nil afterDelay:0.3f];
    }
}

@end
