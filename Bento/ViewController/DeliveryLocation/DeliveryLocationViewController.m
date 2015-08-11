//
//  DeliveryLocationViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "DeliveryLocationViewController.h"

#import "AppDelegate.h"

#import "CustomBentoViewController.h"
#import "FixedBentoViewController.h"

#import "CompleteOrderViewController.h"
#import "OutOfDeliveryAddressViewController.h"
#import "FaqViewController.h"

#import "FXBlurView.h"
#import "MyAlertView.h"

#import "BentoShop.h"
#import "AppStrings.h"
#import "WebManager.h"
#import "DataManager.h"

#import "SVGeocoder.h"
#import <MapKit/MapKit.h>
#import "NSUserDefaults+RMSaveCustomObject.h"

#import "JGProgressHUD.h"

@interface DeliveryLocationViewController () <MKMapViewDelegate, MyAlertViewDelegate>
{
    BOOL _nextToBuild;
    BOOL _showedLocationTableView;
    
    JGProgressHUD *loadingHUD;
}

@property (nonatomic, weak) IBOutlet UILabel *lblTitle;
@property (nonatomic, weak) IBOutlet UIButton *btnBack;

@property (nonatomic, weak) IBOutlet UIView *viewSearchLocation;

@property (nonatomic, weak) IBOutlet UITextField *txtAddress;
@property (nonatomic, weak) IBOutlet UITableView *tvLocations;

@property (nonatomic, weak) IBOutlet MKMapView *mapView;

@property (nonatomic, weak) IBOutlet UIView *viewError;
@property (nonatomic, weak) IBOutlet UILabel *lblError;

@property (nonatomic, weak) IBOutlet UILabel *lblAgree;
@property (nonatomic, weak) IBOutlet UIButton *btnMeetMyDrive;

@property (nonatomic, weak) IBOutlet UIButton *btnBottomButton;

@property (nonatomic) SVPlacemark *placeInfo;

@property (nonatomic) MKPointAnnotation *mapAnnotation;

@property (nonatomic) NSMutableArray *aryDisplay;

@end

@implementation DeliveryLocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [SVGeocoder setGoogleMapsAPIKey:GOOGLE_API_KEY];
    
    self.lblTitle.text = [[AppStrings sharedInstance] getString:LOCATION_TITLE];
    [self.txtAddress setPlaceholder:[[AppStrings sharedInstance] getString:LOCATION_PLACEHOLDER_ADDRESS]];
    self.lblAgree.text = [[AppStrings sharedInstance] getString:LOCATION_TEXT_AGREE];
    self.lblError.text = [[AppStrings sharedInstance] getString:LOCATION_AGREE_ERROR];
    [self.btnBottomButton setTitle:[[AppStrings sharedInstance] getString:LOCATION_BUTTON_CONTINUE] forState:UIControlStateNormal];
    
    [[self.txtAddress valueForKey:@"textInputTraits"] setValue:[UIColor colorWithRed:138.0f / 255.0f green:187.0f / 255.0f blue:90.0f / 255.0f alpha:1.0f] forKey:@"insertionPointColor"];
    
    _showedLocationTableView = NO;
    
    float tableViewPos = self.viewSearchLocation.frame.origin.y + CGRectGetHeight(self.viewSearchLocation.frame);
    self.tvLocations.frame = CGRectMake(0, tableViewPos, CGRectGetWidth(self.view.frame), 0);
    
    MKPolygon *polygon = [[BentoShop sharedInstance] getPolygon];
    [self.mapView addOverlay:polygon];
    
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapMapView:)];
    singleTapRecognizer.numberOfTapsRequired = 1;
    [self.mapView addGestureRecognizer:singleTapRecognizer];
    singleTapRecognizer = nil;

    self.mapAnnotation = nil;
    self.aryDisplay = nil;
    
    self.placeInfo = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"];
    
    self.viewError.alpha = 0.0f;
    
    if (self.placeInfo != nil)
    {
        self.btnMeetMyDrive.selected = YES;
        
        self.txtAddress.text = self.placeInfo.formattedAddress;

        MKCoordinateRegion mapRegion;
        mapRegion.center = self.placeInfo.location.coordinate;
        
        if (self.isFromOrder)
        {
            mapRegion.span.latitudeDelta = 0.005;
            mapRegion.span.longitudeDelta = 0.005;
        }
        else
        {
            mapRegion.span.latitudeDelta = 0.2;
            mapRegion.span.longitudeDelta = 0.2;
        }
        
        [self.mapView setRegion:mapRegion animated: YES];
    }
    else
    {
        self.btnMeetMyDrive.selected = NO;
        
        self.txtAddress.text = @"";
        
        // Move to current location and zoom enough
        MKCoordinateRegion mapRegion;
        AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        CLLocationCoordinate2D curLocation = [appDelegate getCurrentLocation];
        if (curLocation.latitude == 0 && curLocation.longitude == 0)
        {
            // Move to delivery location
            MKMapRect curRect = [polygon boundingMapRect];
            UIEdgeInsets insets = UIEdgeInsetsMake(50, 50, 50, 50);
            MKMapRect newRect = [self.mapView mapRectThatFits:curRect edgePadding:insets];
            [self.mapView setRegion:MKCoordinateRegionForMapRect(newRect)];
        }
        else
        {
            mapRegion.center = curLocation;
            mapRegion.span.latitudeDelta = 0.005;
            mapRegion.span.longitudeDelta = 0.005;
            [self.mapView setRegion:mapRegion animated: YES];
        }
    }
    
    _nextToBuild = NO;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"nextToBuild"])
    {
        _nextToBuild = YES;
        
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"nextToBuild"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if (_nextToBuild)
        self.btnBack.hidden = YES;
    else
        self.btnBack.hidden = NO;
    
//    if (!self.isFromOrder)
//    {
//        self.priceDiscount = 0;
//        self.strPromoCode = nil;
//    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"OutOfDelivery"])
    {
        OutOfDeliveryAddressViewController *vcOutOfZone = segue.destinationViewController;
        vcOutOfZone.strAddress = (NSString *)sender;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_MENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:self.txtAddress];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCurrentMode) name:@"enteredForeground" object:nil];
    
    [self updateUI];
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

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super viewWillDisappear:animated];
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

- (void) onUpdatedStatus:(NSNotification *)notification
{
    if ([[BentoShop sharedInstance] isClosed] && ![[DataManager shareDataManager] isAdminUser])
        [self showSoldoutScreen:[NSNumber numberWithInt:0]];
    else if ([[BentoShop sharedInstance] isSoldOut] && ![[DataManager shareDataManager] isAdminUser])
        [self showSoldoutScreen:[NSNumber numberWithInt:1]];
    else
        [self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
}

- (IBAction)onBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) gotoAddAnotherBentoScreen
{
    [self stopSearch];
    
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    for (UIViewController *vc in viewControllers)
    {
        // serving dinner vc || serving lunch vc
        if ([vc isKindOfClass:[CustomBentoViewController class]] || [vc isKindOfClass:[FixedBentoViewController class]])
        {
            if (self.isFromOrder)
            {
                [self.navigationController popToViewController:vc animated:YES];
                
                CompleteOrderViewController *completeOrderViewController = [[CompleteOrderViewController alloc] init];
                [self.navigationController pushViewController:completeOrderViewController animated:YES];
            }
            else
                [self.navigationController popToViewController:vc animated:YES];
            
            return;
        }
    }
    
/*-----check if dinner or lunch mode-----*/
    
    float currentTime = [[[BentoShop sharedInstance] getCurrentTime] floatValue];
    float dinnerTime = [[[BentoShop sharedInstance] getDinnerTime] floatValue];
    
    // 12:00am - dinner opening (ie. 16.5)
    if (currentTime >= 0 && currentTime < dinnerTime)
    {
        FixedBentoViewController *servingLunchViewController = [[FixedBentoViewController alloc] init];
        [self.navigationController popToViewController:servingLunchViewController animated:YES];
        
    // dinner opening - 11:59pm
    }
    else if (currentTime >= dinnerTime && currentTime < 24)
    {
        CustomBentoViewController *customBentoViewController = [[CustomBentoViewController alloc] init];
        [self.navigationController popToViewController:customBentoViewController animated:YES];
    }
}

- (void)doConfirmOrder
{
    if (!self.btnMeetMyDrive.selected)
    {
        [UIView animateWithDuration:0.3f animations:^{
            
            self.viewError.alpha = 1.0f;
            
        } completion:^(BOOL finished) {
            
            [self performSelector:@selector(hideErrorView) withObject:nil afterDelay:3.0f];
            
        }];
        
        return;
    }
    
    [self stopSearch];
    
    if (self.placeInfo == nil) {
        
        [[NSUserDefaults standardUserDefaults] rm_setCustomObject:self.placeInfo forKey:@"delivery_location"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.navigationController popViewControllerAnimated:YES];
        
    } else {
        CLLocationCoordinate2D location = self.placeInfo.location.coordinate;
        if (![[BentoShop sharedInstance] checkLocation:location]) {
            [self gotoNoneDeliveryAreaScreen];
        } else {
            [[NSUserDefaults standardUserDefaults] rm_setCustomObject:self.placeInfo forKey:@"delivery_location"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self.navigationController popViewControllerAnimated:YES];
            
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"isFromHomepage"] isEqualToString:@"YES"])
            {
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                CompleteOrderViewController *completeOrderViewController = [storyboard instantiateViewControllerWithIdentifier:@"CompleteOrderViewController"];
                [self.navigationController pushViewController:completeOrderViewController animated:YES];
                
                [[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:@"isFromHomepage"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
    }
}

- (void)addAnnotation:(CLLocationCoordinate2D)coordinate
{
    if (self.mapAnnotation != nil)
    {
        [self.mapView removeAnnotation:self.mapAnnotation];
        self.mapAnnotation = nil;
    }
    
    self.mapAnnotation = [[MKPointAnnotation alloc] init];
    self.mapAnnotation.coordinate = coordinate;
    
    [self.mapView addAnnotation:self.mapAnnotation];
    
    self.placeInfo = nil;
    
    [SVGeocoder reverseGeocode:coordinate completion:^(NSArray *placemarks, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (error == nil && placemarks.count > 0)
        {
            SVPlacemark *placeMark = [placemarks firstObject];
            self.placeInfo = placeMark;
            self.txtAddress.text = placeMark.formattedAddress;
            NSLog(@"Address: %@", self.txtAddress.text);
            [self updateUI];
        }
        else
        {
            self.placeInfo = nil;
            self.txtAddress.text = @"";
            [self updateUI];
        }
    }];
}

- (IBAction)onNavigation:(id)sender
{
    [self stopSearch];
    
    CLLocationCoordinate2D curLocation = self.mapView.userLocation.location.coordinate;
    if (curLocation.latitude != 0 && curLocation.longitude != 0)
    {
        [self.mapView setCenterCoordinate:curLocation animated:YES];
        [self addAnnotation:self.mapView.userLocation.location.coordinate];
    }
}

- (IBAction)onSearchLocation:(id)sender
{
    if (_showedLocationTableView)
        [self stopSearch];
    else
        [self startSearch];
}

- (IBAction)onHelp:(id)sender
{
    NSString *strText = [[AppStrings sharedInstance] getString:ALERT_DA_TEXT];
    NSString *strConfirm = [[AppStrings sharedInstance] getString:ALERT_DA_BUTTON_CONFIRM];
    NSString *strCancel = [[AppStrings sharedInstance] getString:ALERT_DA_BUTTON_CANCEL];
    
    MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:strText delegate:self cancelButtonTitle:strCancel otherButtonTitle:strConfirm];
    alertView.tag = 0;
    
    [alertView showInView:self.view];
    alertView = nil;
}

- (IBAction)onFAQ:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FaqViewController *destVC = [storyboard instantiateViewControllerWithIdentifier:@"FAQID"];
    destVC.contentType = CONTENT_FAQ;
    [self.navigationController pushViewController:destVC animated:YES];
}


- (IBAction)onMeetMyDriver:(id)sender
{
    if (self.btnMeetMyDrive.selected)
    {
        self.btnMeetMyDrive.selected = NO;
        [self updateUI];
    }
    else
    {
        self.btnMeetMyDrive.selected = YES;
        [self updateUI];
    }
}

- (IBAction)onChangeAddress:(id)sender
{
    [self updateUI];
}

- (void)hideErrorView
{
    [UIView animateWithDuration:0.3f animations:^{
        
        self.viewError.alpha = 0.0f;
        
    } completion:^(BOOL finished) {
        
    }];
}

- (IBAction)onBottomButton:(id)sender
{
    if (!self.btnMeetMyDrive.selected)
    {
        [UIView animateWithDuration:0.3f animations:^{
            
            self.viewError.alpha = 1.0f;
            
        } completion:^(BOOL finished) {
            
            [self performSelector:@selector(hideErrorView) withObject:nil afterDelay:3.0f];
            
        }];
        
        return;
    }
    
    if (_nextToBuild)
    {
        [self stopSearch];
        
        if (self.placeInfo == nil)
            return;

        CLLocationCoordinate2D location = self.placeInfo.location.coordinate;
        if (![[BentoShop sharedInstance] checkLocation:location])
            [self gotoNoneDeliveryAreaScreen];
        else
        {
            [[NSUserDefaults standardUserDefaults] rm_setCustomObject:self.placeInfo forKey:@"delivery_location"];
            
            [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%f", self.placeInfo.location.coordinate.latitude] forKey:@"savedLatitude"];
            [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%f", self.placeInfo.location.coordinate.longitude] forKey:@"savedLongitude"];
            
            [NSUserDefaults standardUserDefaults];
            
            [self gotoAddAnotherBentoScreen];
        }
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%f", self.placeInfo.location.coordinate.latitude] forKey:@"savedLatitude"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%f", self.placeInfo.location.coordinate.longitude] forKey:@"savedLongitude"];
        [NSUserDefaults standardUserDefaults];
        
        [self doConfirmOrder];
    }
}

- (void) gotoNoneDeliveryAreaScreen
{
    [self stopSearch];
    
    [self performSegueWithIdentifier:@"OutOfDelivery" sender:self.placeInfo.formattedAddress];
}

- (void) startSearch
{
    [self showLocationTableView];
}

- (void) stopSearch
{
    [self hideKeyboard];
    [self hideLocationTableView];
}

- (void) showLocationTableView
{
    if (_showedLocationTableView) return;
    
    _showedLocationTableView = YES;
    
    float keyboardHeight = 216;
    float tableViewPos = self.viewSearchLocation.frame.origin.y + CGRectGetHeight(self.viewSearchLocation.frame);
    
    self.tvLocations.frame = CGRectMake(0, tableViewPos, CGRectGetWidth(self.view.frame), 0);
    
    [UIView animateWithDuration:0.3f animations:^{
        
        self.tvLocations.frame = CGRectMake(0, tableViewPos, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - (tableViewPos + keyboardHeight));
        
    } completion:^(BOOL finished) {
        
    }];
}

- (void) hideLocationTableView
{
    if (!_showedLocationTableView) return;
    
    _showedLocationTableView = NO;
    
    [UIView animateWithDuration:0.3f animations:^{
        
        float tableViewPos = self.viewSearchLocation.frame.origin.y + CGRectGetHeight(self.viewSearchLocation.frame);
        self.tvLocations.frame = CGRectMake(0, tableViewPos, CGRectGetWidth(self.view.frame), 0);
        
    } completion:^(BOOL finished) {
        
    }];
}

- (void)hideKeyboard
{
    [self.txtAddress resignFirstResponder];
}

- (void)updateUI
{
    if (self.mapAnnotation != nil)
    {
        [self.mapView removeAnnotation:self.mapAnnotation];
        self.mapAnnotation = nil;
    }
    
    if (self.placeInfo != nil)
    {
        self.mapAnnotation = [[MKPointAnnotation alloc] init];
        self.mapAnnotation.coordinate = self.placeInfo.location.coordinate;
        
//        self.txtAddress.text = [DataManager getAddressString:self.placeInfo];
        
        [self.mapView addAnnotation:self.mapAnnotation];
        self.mapView.centerCoordinate = self.mapAnnotation.coordinate;
    }
    else
    {
//        self.txtAddress.text = @"";
    }
    
    if (self.placeInfo != nil && self.btnMeetMyDrive.selected && [[BentoShop sharedInstance] getCompletedBentoCount] > 0)
    {
        NSString *strTitle = @"CONFIRM ADDRESS";
        
        [self.btnBottomButton setTitle:strTitle forState:UIControlStateNormal];
        NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
        float spacing = 1.0f;
        [attributedTitle addAttribute:NSKernAttributeName
                                value:@(spacing)
                                range:NSMakeRange(0, [strTitle length])];
        
        // Anything less than iOS 8.0
        if ([[UIDevice currentDevice].systemVersion intValue] < 8)
            self.btnBottomButton.titleLabel.text = strTitle;
        else
            self.btnBottomButton.titleLabel.attributedText = attributedTitle;
        
        self.btnBottomButton.backgroundColor = [UIColor colorWithRed:135.0f / 255.0f green:176.0f / 255.0f blue:95.0f / 255.0f alpha:1.0f];
    }
    else
    {
        if (self.placeInfo != nil && self.btnMeetMyDrive.selected && _nextToBuild)
        {
            NSString *strTitle = @"CONFIRM ADDRESS";
            
            [self.btnBottomButton setTitle:strTitle forState:UIControlStateNormal];
            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
            float spacing = 1.0f;
            [attributedTitle addAttribute:NSKernAttributeName
                                    value:@(spacing)
                                    range:NSMakeRange(0, [strTitle length])];
            
            // Anything less than iOS 8.0
            if ([[UIDevice currentDevice].systemVersion intValue] < 8)
                self.btnBottomButton.titleLabel.text = strTitle;
            else
                self.btnBottomButton.titleLabel.attributedText = attributedTitle;
            
            self.btnBottomButton.backgroundColor = [UIColor colorWithRed:135.0f / 255.0f green:176.0f / 255.0f blue:95.0f / 255.0f alpha:1.0f];
        }
        else
        {
            NSString *strTitle = [[AppStrings sharedInstance] getString:LOCATION_BUTTON_CONTINUE];
            
            if (strTitle != nil)
            {
                [self.btnBottomButton setTitle:strTitle forState:UIControlStateNormal];
                NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
                float spacing = 1.0f;
                [attributedTitle addAttribute:NSKernAttributeName
                                        value:@(spacing)
                                        range:NSMakeRange(0, [strTitle length])];
                
                // Anything less than iOS 8.0
                if ([[UIDevice currentDevice].systemVersion intValue] < 8)
                    self.btnBottomButton.titleLabel.text = strTitle;
                else
                    self.btnBottomButton.titleLabel.attributedText = attributedTitle;
            }
            
            self.btnBottomButton.backgroundColor = [UIColor colorWithRed:122.0f / 255.0f green:133.0f / 255.0f blue:145.0f / 255.0f alpha:1.0f];
        }
    }
}

- (void)onTapMapView:(UITapGestureRecognizer *)recognizer
{
    CGPoint point = [recognizer locationInView:self.mapView];
    CLLocationCoordinate2D tapPoint = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
    [self addAnnotation:tapPoint];
}

#pragma mark UITextFieldDelegate

- (CLLocationDistance)getDistanceFrom:(CLLocationCoordinate2D)start to:(CLLocationCoordinate2D)end
{
    CLLocation *startLoc = [[CLLocation alloc] initWithLatitude:start.latitude longitude:start.longitude];
    CLLocation *endLoc = [[CLLocation alloc] initWithLatitude:end.latitude longitude:end.longitude];
    CLLocationDistance retVal = [startLoc distanceFromLocation:endLoc];
    
    return retVal;
}

- (void)geocodeAddress
{
    NSString *strSearch = self.txtAddress.text;
    
    NSArray *aryStrings = [strSearch componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    strSearch = @"";
    for (NSString *subString in aryStrings)
    {
        if (strSearch.length == 0)
            strSearch = subString;
        else
            strSearch = [NSString stringWithFormat:@"%@+%@", strSearch, subString];
    }
    
    MKMapRect mRect = self.mapView.visibleMapRect;
    MKMapPoint neMapPoint = MKMapPointMake(MKMapRectGetMaxX(mRect), mRect.origin.y);
    MKMapPoint swMapPoint = MKMapPointMake(mRect.origin.x, MKMapRectGetMaxY(mRect));
    CLLocationCoordinate2D neCoord = MKCoordinateForMapPoint(neMapPoint);
    CLLocationCoordinate2D swCoord = MKCoordinateForMapPoint(swMapPoint);
    CLLocationDistance diameter = [self getDistanceFrom:neCoord to:swCoord];
    
    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:self.mapView.centerCoordinate radius:(diameter/2) identifier:@"mapWindow"];
    
    [SVGeocoder geocode:strSearch region:region completion:^(NSArray *placemarks, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (error == nil && placemarks.count > 0)
        {
            if (self.aryDisplay != nil)
                self.aryDisplay = nil;
            
            self.aryDisplay = [[NSMutableArray alloc] init];
            for (SVPlacemark *placeMark in placemarks)
            {
                if (placeMark.subThoroughfare == nil && placeMark.thoroughfare == nil)
                    continue;
                
                if (placeMark.locality == nil && placeMark.administrativeAreaCode == nil)
                    continue;
                
                [self.aryDisplay addObject:placeMark];
            }
            
            [self.tvLocations reloadData];
        }
        else
        {
            self.aryDisplay = nil;
            [self.tvLocations reloadData];
        }
    }];
}

- (void)textFieldDidChange:(NSNotification *)notification
{
    self.placeInfo = nil;
    [self updateUI];
    
    self.aryDisplay = nil;
    [self.tvLocations reloadData];
    
//    if (_isSearching)
//        return;
//
//    _isSearching = YES;
    
    [self geocodeAddress];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    [self startSearch];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
//    [self stopSearch];
    
    return YES;
}

#pragma mark MKMapViewDelegate
/*
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay
{
    MKPolygonRenderer *polygonView = [[MKPolygonRenderer alloc] initWithOverlay:overlay];
    polygonView.alpha = 0.3f;
    polygonView.lineWidth = 1.0;
    polygonView.strokeColor = [UIColor redColor];
    polygonView.fillColor = [UIColor greenColor];
    return polygonView;
}
*/
#pragma mark MyAlertViewDelegate

- (void)alertView:(MyAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 0)
    {
        if (buttonIndex == 0)
        {
//            self.btnMeetMyDrive.selected = NO;
//            [self updateUI];
        }
        else if (buttonIndex == 1)
        {
            self.btnMeetMyDrive.selected = YES;
            [self updateUI];
        }
    }
}
	
#pragma mark UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.aryDisplay == nil)
        return 0;
    
    return self.aryDisplay.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.font = [UIFont fontWithName:@"Open Sans" size:14.0f];
    cell.detailTextLabel.font = [UIFont fontWithName:@"Open Sans" size:12.0f];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
//    NSDictionary *placeInfo = [self.aryDisplay objectAtIndex:indexPath.row];
//    if (placeInfo != nil)
//        cell.textLabel.text = [placeInfo objectForKey:@"formatted_address"];
    SVPlacemark *placeMark = [self.aryDisplay objectAtIndex:indexPath.row];
    
    if (placeMark.subThoroughfare && placeMark.thoroughfare)
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", placeMark.subThoroughfare, placeMark.thoroughfare];
    else if (placeMark.subThoroughfare)
        cell.textLabel.text = placeMark.subThoroughfare;
    else if (placeMark.thoroughfare)
        cell.textLabel.text = placeMark.thoroughfare;
    else
        cell.textLabel.text = @"";
    
    if (placeMark.locality && placeMark.administrativeAreaCode)
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", placeMark.locality, placeMark.administrativeAreaCode];
    else if (placeMark.locality)
        cell.detailTextLabel.text = placeMark.locality;
    else if (placeMark.thoroughfare)
        cell.detailTextLabel.text = placeMark.administrativeArea;
    else
        cell.detailTextLabel.text = @"";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self stopSearch];
    
    self.placeInfo = [self.aryDisplay objectAtIndex:indexPath.row];
    self.txtAddress.text = self.placeInfo.formattedAddress;
    [self updateUI];
    
//    MKMapRect mapRect = [self.mapView visibleMapRect];
//    MKMapPoint pt = MKMapPointForCoordinate([self.mapAnnotation coordinate]);
//    mapRect.origin.x = pt.x - mapRect.size.width * 0.5;
//    mapRect.origin.y = pt.y - mapRect.size.height * 0.25;
//    [self.mapView setVisibleMapRect:mapRect animated:YES];
}

@end
