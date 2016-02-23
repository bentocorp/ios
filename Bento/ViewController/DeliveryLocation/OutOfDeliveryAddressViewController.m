//
//  OutOfDeliveryAddressViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "OutOfDeliveryAddressViewController.h"

#import "FaqViewController.h"

#import "MyAlertView.h"

#import "JGProgressHUD.h"

#import "BentoShop.h"
#import "WebManager.h"
#import "AppStrings.h"
#import "DataManager.h"

#import <MapKit/MapKit.h>

#import "Mixpanel.h"

#import "NSUserDefaults+RMSaveCustomObject.h"
#import "SVPlacemark.h"

@interface OutOfDeliveryAddressViewController () /*<UIWebViewDelegate>*/

@property (nonatomic, weak) IBOutlet UILabel *lblTitle;

@property (nonatomic, weak) IBOutlet UILabel *lblAddress;

@property (nonatomic, weak) IBOutlet UIView *viewOver;

@property (nonatomic, weak) IBOutlet UILabel *lblMiddleTitle;

@property (nonatomic, weak) IBOutlet UILabel *lblMiddleText;

@property (nonatomic, weak) IBOutlet UITextField *txtEmail;

@property (nonatomic, weak) IBOutlet UIButton *btnSend;

//@property (nonatomic, weak) IBOutlet UIWebView *webView;

@end

@implementation OutOfDeliveryAddressViewController
{
    UIActivityIndicatorView *viewActivity;
    
    JGProgressHUD *loadingHUD;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    /*-------------------------------------------------------------------------------*/
//    
//    // this screen is ONLY shown if selected address is outside service area
//    // if there is a saved address, show alert. i don't need to check if that saved address is within service area on this screen, because it has already been checked before coming here..
//    // if invalid selected address is different from invalid saved address, then no need to display alert
//    // make sure they match before displaying alert
//    
//    SVPlacemark *placeInfo;
//    
//    // check if address was saved
//    if ([[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"] != nil) {
//        
//        // if saved, get placeInfo
//        placeInfo = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"];
//        
//        // if saved address (no longer valid) == selected address (invalid)
//        if ([placeInfo.formattedAddress isEqualToString:self.strAddress]) {
//        
//            // set savedAddress string
//            NSString *savedAddress;
//            if (placeInfo.subThoroughfare && placeInfo.thoroughfare) {
//                savedAddress = [NSString stringWithFormat:@"%@ %@", placeInfo.subThoroughfare, placeInfo.thoroughfare];
//            }
//            else if (placeInfo.subThoroughfare) {
//                savedAddress = placeInfo.subThoroughfare;
//            }
//            else if (placeInfo.thoroughfare) {
//                savedAddress = placeInfo.thoroughfare;
//            }
//            else {
//                savedAddress = @"";
//            }
//        
//            // get current mode
////            NSString *currentMode;
////            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"OriginalLunchOrDinnerMode"] isEqualToString:@"LunchMode"]) {
////                currentMode = @"Lunch";
////            }
////            else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"OriginalLunchOrDinnerMode"] isEqualToString:@"DinnerMode"]) {
////                currentMode = @"Dinner";
////            }
//            
//            // alert user that saved address is unavailable
//            NSString *alertString = [NSString stringWithFormat:@"Sorry, we've updated our delivery zone! %@ is temporarily unavailable", savedAddress];
//            MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:alertString delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
//            [alertView showInView:self.view];
//        }
//    }
    
    /*-------------------------------------------------------------------------------*/

    self.lblTitle.text = @"Delivery Zone"; // hardcoded instead of [[AppStrings sharedInstance] getString:OUTOFAREA_TITLE]
    self.lblMiddleTitle.text = [[AppStrings sharedInstance] getString:OUTOFAREA_MIDDLE_TITLE];
    self.lblMiddleText.text = [[AppStrings sharedInstance] getString:OUTOFAREA_TEXT_CONTENT];
    self.txtEmail.placeholder = [[AppStrings sharedInstance] getString:OUTOFAREA_PLACEHOLDER_EMAIL];
    [self.btnSend setTitle:[[AppStrings sharedInstance] getString:OUTOFAREA_BUTTON_RECEIVE_COUPON] forState:UIControlStateNormal];
    
//    MKPolygon *polygon = [[BentoShop sharedInstance] getPolygon];
//    [self.mapView addOverlay:polygon];
//    
//    MKMapRect curRect = [polygon boundingMapRect];
//    UIEdgeInsets insets = UIEdgeInsetsMake(50, 50, 50, 50);
//    MKMapRect newRect = [self.mapView mapRectThatFits:curRect edgePadding:insets];
//    [self.mapView setRegion:MKCoordinateRegionForMapRect(newRect)];
    
    [self.lblAddress setText:self.placeInfo.formattedAddress];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Selected Address Outside of Service Area" properties:@{
                                                                             @"Address": self.placeInfo.formattedAddress
                                                                            }];
    
    NSLog(@"SELECTED ADDRESS: %@", self.placeInfo.formattedAddress);
    
//// set map view
//    float currentTime = [[[BentoShop sharedInstance] getCurrentTime] floatValue];
//    float dinnerTime = [[[BentoShop sharedInstance] getDinnerTime] floatValue];
//    
//    NSURL *url;
//    
//    if ([[BentoShop sharedInstance] isAllDay])
//    {
//        if ([[BentoShop sharedInstance] isThereLunchMenu])
//            url = [NSURL URLWithString:[[BentoShop sharedInstance] getLunchMapURL]];
//        else // todayDinner is available
//            url = [NSURL URLWithString:[[BentoShop sharedInstance] getDinnerMapURL]];
//    }
//    else // not all day
//    {
//        // 12:00am - dinner opening (ie. 16.5)
//        if (currentTime >= 0 && currentTime < dinnerTime)
//            url = [NSURL URLWithString:[[BentoShop sharedInstance] getLunchMapURL]];
//        // dinner opening - 11:59pm
//        else if (currentTime >= dinnerTime && currentTime < 24)
//            url = [NSURL URLWithString:[[BentoShop sharedInstance] getDinnerMapURL]];
//    }
    
//    NSURLRequest *request = [NSURLRequest requestWithURL:url];
//    [self.webView loadRequest:request];
//    
//    viewActivity = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(self.webView.frame.size.width/2-10, self.webView.frame.size.width/2-40, 20, 20)];
//    viewActivity.color = [UIColor grayColor];
//    [self.webView addSubview:viewActivity];
    
//    viewActivity.hidden = NO;
//    [viewActivity startAnimating];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willChangeKeyboardFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimerOnViewedScreen) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endTimerOnViewedScreen) name:@"enteringBackground" object:nil];
    
    [self startTimerOnViewedScreen];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
    
    [self endTimerOnViewedScreen];
}

#pragma mark Duration on screen
- (void)startTimerOnViewedScreen
{
    [[Mixpanel sharedInstance] timeEvent:@"Viewed Out of Delivery Zone Screen"];
}

- (void)endTimerOnViewedScreen
{
    [[Mixpanel sharedInstance] track:@"Viewed Out of Delivery Zone Screen"];
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

- (void) willShowKeyboard:(NSNotification*)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    [self proccessWhenShowKeyboard:keyboardFrameBeginRect.size.height];
}

- (void) willChangeKeyboardFrame:(NSNotification *)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    [self proccessWhenShowKeyboard:keyboardFrameBeginRect.size.height];
}

- (void) willHideKeyboard:(NSNotification *)notification
{
    [self processWhenHideKeyboard];
}

- (void) proccessWhenShowKeyboard:(float)keyboardHeight
{
    [self.view bringSubviewToFront:self.viewOver];
    
    [UIView animateWithDuration:0.3f animations:^{
        
        self.viewOver.frame = CGRectMake(self.viewOver.frame.origin.x, self.view.frame.size.height - (keyboardHeight + self.viewOver.frame.size.height), self.viewOver.frame.size.width, self.viewOver.frame.size.height);
        
    } completion:^(BOOL finished) {
        
    }];
}

- (void) processWhenHideKeyboard
{
    [UIView animateWithDuration:0.3f animations:^{
        
        self.viewOver.frame = CGRectMake(self.viewOver.frame.origin.x, self.view.frame.size.height - (45 + self.viewOver.frame.size.height), self.viewOver.frame.size.width, self.viewOver.frame.size.height);
        
    } completion:^(BOOL finished) {
        
    }];
}

- (IBAction)onBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onChangeAddress:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showConfirmMessage
{
    MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:@"Thanks! We'll let you know when we're in your area." delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
    
    [alertView showInView:self.view];
    alertView = nil;
}

- (void)doSubmit
{
    NSString *strEmail = self.txtEmail.text;
    if (![DataManager isValidMailAddress:strEmail])
    {
        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:@"Please input a valid email address." delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
        
        [alertView showInView:self.view];
        alertView = nil;
        return;
    }
    
    NSString *strReason = @"outside of delivery zone";
    
    NSString *strToken = [[DataManager shareDataManager] getAPIToken];
    NSDictionary* postInfo = nil;
    if (strToken != nil && strToken.length > 0)
    {
        postInfo = @{
                     @"email"       : strEmail,
                     @"reason"      : strReason,
                     @"api_token"   : strToken,
                     @"address"     : self.placeInfo.formattedAddress,
                     @"lat"         : [NSString stringWithFormat:@"%f", self.placeInfo.location.coordinate.latitude],
                     @"long"        : [NSString stringWithFormat:@"%f", self.placeInfo.location.coordinate.longitude]
                     };
    }
    else
    {
        postInfo = @{
                     @"email"   : strEmail,
                     @"reason"  : strReason,
                     @"address" : self.placeInfo.formattedAddress,
                     @"lat"     : [NSString stringWithFormat:@"%f", self.placeInfo.location.coordinate.latitude],
                     @"long"    : [NSString stringWithFormat:@"%f", self.placeInfo.location.coordinate.longitude]
                     };
    }
    
    NSLog(@"postinfo - %@", postInfo);
    
    NSDictionary *dicRequest = @{@"data" : [postInfo jsonEncodedKeyValueString]};
    WebManager *webManager = [[WebManager alloc] init];
    
    loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Sending...";
    [loadingHUD showInView:self.view];
    
    NSString *strRequest = [NSString stringWithFormat:@"%@/coupon/request", SERVER_URL];
    if ([[DataManager shareDataManager] getUserInfo] != nil)
        strRequest = [NSString stringWithFormat:@"%@?api_token=%@", strRequest, [[DataManager shareDataManager] getAPIToken]];
    
    [webManager AsyncProcess:strRequest method:POST parameters:dicRequest success:^(MKNetworkOperation *networkOperation) {
        [loadingHUD dismiss];
        
        [self showConfirmMessage];
        
    } failure:^(MKNetworkOperation *errorOp, NSError *error) {
        [loadingHUD dismiss];
        
        NSString *strMessage = [[DataManager shareDataManager] getErrorMessage:errorOp.responseJSON];
        if (strMessage == nil)
            strMessage = error.localizedDescription;
        
        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:strMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
        
        [alertView showInView:self.view];
        alertView = nil;
        
    } isJSON:NO];
    
    // reset text field
    self.txtEmail.text = @"";
}

- (IBAction)onSendFreeCoupon:(id)sender
{
    [self doSubmit];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.txtEmail resignFirstResponder];
    return YES;
}

//#pragma mark MKMapViewDelegate
//
//- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay
//{
//    MKPolygonRenderer *polygonView = [[MKPolygonRenderer alloc] initWithOverlay:overlay];
//    polygonView.alpha = 0.3f;
//    polygonView.lineWidth = 1.0;
//    polygonView.strokeColor = [UIColor redColor];
//    polygonView.fillColor = [UIColor greenColor];
//    return polygonView;
//}
//
//#pragma mark UIWebViewDelegate
//
//- (void)hideActivityView
//{
//    [viewActivity stopAnimating];
//    viewActivity.hidden = YES;
//}
//
//- (void)webViewDidFinishLoad:(UIWebView *)webView
//{
//    [self hideActivityView];
//}
//
//- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
//{
//    [self hideActivityView];
//    
//    MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Error" message:error.description delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
//    [alertView showInView:self.view];
//    alertView = nil;
//}

@end
