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

@interface OutOfDeliveryAddressViewController ()

@property (nonatomic, assign) IBOutlet MKMapView *mapView;

@property (nonatomic, assign) IBOutlet UILabel *lblTitle;

@property (nonatomic, assign) IBOutlet UILabel *lblAddress;

@property (nonatomic, assign) IBOutlet UIView *viewOver;

@property (nonatomic, assign) IBOutlet UILabel *lblMiddleTitle;

@property (nonatomic, assign) IBOutlet UILabel *lblMiddleText;

@property (nonatomic, assign) IBOutlet UITextField *txtEmail;

@property (nonatomic, assign) IBOutlet UIButton *btnSend;

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation OutOfDeliveryAddressViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.lblTitle.text = @"Delivery Zone"; // hardcoded instead of [[AppStrings sharedInstance] getString:OUTOFAREA_TITLE]
    self.lblMiddleTitle.text = [[AppStrings sharedInstance] getString:OUTOFAREA_MIDDLE_TITLE];
    self.lblMiddleText.text = [[AppStrings sharedInstance] getString:OUTOFAREA_TEXT_CONTENT];
    self.txtEmail.placeholder = [[AppStrings sharedInstance] getString:OUTOFAREA_PLACEHOLDER_EMAIL];
    [self.btnSend setTitle:[[AppStrings sharedInstance] getString:OUTOFAREA_BUTTON_RECEIVE_COUPON] forState:UIControlStateNormal];
    
    MKPolygon *polygon = [[BentoShop sharedInstance] getPolygon];
    [self.mapView addOverlay:polygon];
    
    MKMapRect curRect = [polygon boundingMapRect];
    UIEdgeInsets insets = UIEdgeInsetsMake(50, 50, 50, 50);
    MKMapRect newRect = [self.mapView mapRectThatFits:curRect edgePadding:insets];
    [self.mapView setRegion:MKCoordinateRegionForMapRect(newRect)];
    
    [self.lblAddress setText:self.strAddress];
    
// set map view
    float currentTime = [[[BentoShop sharedInstance] getCurrentTime] floatValue];
    float dinnerTime = [[[BentoShop sharedInstance] getDinnerTime] floatValue];
    NSURL *url;
    // 12:00am - dinner opening (ie. 16.5)
    if (currentTime >= 0 && currentTime < dinnerTime)
    {
        url = [NSURL URLWithString:@"https://a.tiles.mapbox.com/v4/vincent-bentonow-com.m4b3e43g/page.html?access_token=pk.eyJ1IjoidmluY2VudC1iZW50b25vdy1jb20iLCJhIjoiV0p2al9qNCJ9.cKufaBUS30xSk7wXxmGuDg#13/37.7802/-122.4169"];
    }
    // dinner opening - 11:59pm
    else if (currentTime >= dinnerTime && currentTime < 24)
    {
        url = [NSURL URLWithString:@"https://www.google.com/maps/d/u/0/viewer?mid=zWUXnQ2nSnXg.klwLYVNEU090"];
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
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
                     @"email" : strEmail,
                     @"reason" : strReason,
                     @"api_token" : strToken,
                     };
    }
    else
    {
        postInfo = @{
                     @"email" : strEmail,
                     @"reason" : strReason,
                     };
    }
    
    NSDictionary *dicRequest = @{@"data" : [postInfo jsonEncodedKeyValueString]};
    WebManager *webManager = [[WebManager alloc] init];
    
    JGProgressHUD *loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
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

#pragma mark MKMapViewDelegate

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay
{
    MKPolygonRenderer *polygonView = [[MKPolygonRenderer alloc] initWithOverlay:overlay];
    polygonView.alpha = 0.3f;
    polygonView.lineWidth = 1.0;
    polygonView.strokeColor = [UIColor redColor];
    polygonView.fillColor = [UIColor greenColor];
    return polygonView;
}

@end
