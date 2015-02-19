//
//  DeliveryLocationViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "DeliveryLocationViewController.h"

#import "AppDelegate.h"

#import "MyBentoViewController.h"
#import "CompleteOrderViewController.h"
#import "OutOfDeliveryAddressViewController.h"

#import "FXBlurView.h"
#import "MyAlertView.h"

#import "BentoShop.h"
#import "AppStrings.h"
#import "WebManager.h"
#import "DataManager.h"

#import "SVGeocoder.h"
#import <MapKit/MapKit.h>
#import "NSUserDefaults+RMSaveCustomObject.h"

@interface DeliveryLocationViewController () <MKMapViewDelegate, MyAlertViewDelegate>
{
    BOOL _nextToBuild;
    BOOL _showedLocationTableView;
}

@property (nonatomic, assign) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UIButton *btnBack;

@property (nonatomic, assign) IBOutlet UILabel *lblBadge;
@property (nonatomic, assign) IBOutlet UIButton *btnDelivery;

@property (nonatomic, assign) IBOutlet UIView *viewSearchLocation;

@property (nonatomic, assign) IBOutlet UITextField *txtAddress;
@property (nonatomic, assign) IBOutlet UITableView *tvLocations;

@property (nonatomic, assign) IBOutlet MKMapView *mapView;

@property (weak, nonatomic) IBOutlet UIView *viewError;
@property (weak, nonatomic) IBOutlet UILabel *lblError;

@property (nonatomic, assign) IBOutlet UILabel *lblAgree;
@property (nonatomic, assign) IBOutlet UIButton *btnMeetMyDrive;

@property (nonatomic, assign) IBOutlet UIButton *btnBottomButton;

@property (nonatomic, retain) SVPlacemark *placeInfo;

@property (nonatomic, retain) MKPointAnnotation *mapAnnotation;

@property (nonatomic, retain) NSMutableArray *aryDisplay;

@end

@implementation DeliveryLocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [SVGeocoder setGoogleMapsAPIKey:GOOGLE_API_KEY];
    
    self.lblTitle.text = [[AppStrings sharedInstance] getString:LOCATION_TITLE];
    [self.txtAddress setPlaceholder:[[AppStrings sharedInstance] getString:LOCATION_PLACEHOLDER_ADDRESS]];
    self.lblAgree.text = [[AppStrings sharedInstance] getString:LOCATION_TEXT_AGREE];
    self.lblError.text = [[AppStrings sharedInstance] getString:LOCATION_AGREE_ERROR];
    [self.btnBottomButton setTitle:[[AppStrings sharedInstance] getString:LOCATION_BUTTON_CONTINUE] forState:UIControlStateNormal];
    
    [[self.txtAddress valueForKey:@"textInputTraits"] setValue:[UIColor colorWithRed:138.0f / 255.0f green:187.0f / 255.0f blue:90.0f / 255.0f alpha:1.0f] forKey:@"insertionPointColor"];
    
    self.lblBadge.layer.cornerRadius = self.lblBadge.frame.size.width / 2;
    self.lblBadge.clipsToBounds = YES;
    
    NSInteger bentoCount = [[BentoShop sharedInstance] getCompletedBentoCount];
    if (bentoCount > 0)
    {
        self.lblBadge.text = [NSString stringWithFormat:@"%ld", (long)bentoCount];
        self.lblBadge.hidden = NO;
    }
    else
    {
        self.lblBadge.text = @"";
        self.lblBadge.hidden = YES;
    }
    
    self.btnDelivery.enabled = NO;
    
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
        mapRegion.span.latitudeDelta = 0.2;
        mapRegion.span.longitudeDelta = 0.2;
        [self.mapView setRegion:mapRegion animated: YES];
    }
    else
    {
        self.btnMeetMyDrive.selected = NO;
        
        self.txtAddress.text = @"";
        
        // Move to current location and zoom enough
        MKCoordinateRegion mapRegion;
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
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
    if ([segue.identifier isEqualToString:@"OutOfDelivery"])
    {
        OutOfDeliveryAddressViewController *vcOutOfZone = segue.destinationViewController;
        vcOutOfZone.strAddress = (NSString *)sender;
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_MENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:self.txtAddress];
    
    [self updateUI];
}

- (void)viewWillDisappear:(BOOL)animated
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

- (IBAction)onBack:(id)sender
{
    [self gotoAddAnotherBentoScreen];
}

- (void) gotoAddAnotherBentoScreen
{
    [self stopSearch];
    
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    for (UIViewController *vc in viewControllers) {
        
        if ([vc isKindOfClass:[MyBentoViewController class]])
        {
            [self.navigationController popToViewController:vc animated:YES];
            
            return;
        }
    }
    
    [self performSegueWithIdentifier:@"AddAnotherBento" sender:nil];
}

- (void)doConfirmOrder
{
    [self stopSearch];
    
    if (self.placeInfo == nil)
        [self gotoCompleteOrderScreen];
    else
    {
        CLLocationCoordinate2D location = self.placeInfo.location.coordinate;
        if (![[BentoShop sharedInstance] checkLocation:location])
            [self gotoNoneDeliveryAreaScreen];
        else
            [self gotoCompleteOrderScreen];
    }
}

- (IBAction)onDelivery:(id)sender
{
//    if (self.mapAnnotation == nil && !self.btnMeetMyDrive.selected)
//        return;

    [self doConfirmOrder];
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
//    [self updateUI];
    
    [SVGeocoder reverseGeocode:coordinate completion:^(NSArray *placemarks, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (error == nil && placemarks.count > 0)
        {
            SVPlacemark *placeMark = [placemarks firstObject];
            self.placeInfo = placeMark;
            self.txtAddress.text = placeMark.formattedAddress;
            [self updateUI];
        }
        else
        {
            self.placeInfo = nil;
            self.txtAddress.text = @"";
            [self updateUI];
        }
    }];
/*
    NSString *strRequest = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/geocode/json?latlng=%.6f,%.6f&result_type=street_address&key=%@", coordinate.latitude, coordinate.longitude, GOOGLE_API_KEY];
    
    WebManager *webManager = [[WebManager alloc] init];
    
    [webManager AsyncRequest:strRequest method:GET parameters:nil success:^(MKNetworkOperation *networkOperation) {
        
        NSArray *aryResults = [(NSDictionary *)networkOperation.responseJSON objectForKey:@"results"];
        for (NSDictionary *placeInfo in aryResults)
        {
            NSString *strAddress = [DataManager getAddressString:placeInfo];
            if (strAddress != nil && strAddress.length > 0)
            {
                self.placeInfo = placeInfo;
                break;
            }
        }
        
        self.txtAddress.text = [DataManager getAddressString:self.placeInfo];
        [self updateUI];
        
    } failure:^(MKNetworkOperation *errorOp, NSError *error) {
        
        self.placeInfo = nil;
        self.txtAddress.text = @"";
        [self updateUI];
        
    } isJSON:NO];
*/
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
            [self gotoAddAnotherBentoScreen];
        }
    }
    else
    {
        [self doConfirmOrder];
    }
}

- (void) gotoNoneDeliveryAreaScreen
{
    [self stopSearch];
    [self performSegueWithIdentifier:@"OutOfDelivery" sender:self.placeInfo.formattedAddress];
}

- (void) gotoCompleteOrderScreen
{
    [[NSUserDefaults standardUserDefaults] rm_setCustomObject:self.placeInfo forKey:@"delivery_location"];
    
    if ([[DataManager shareDataManager] getUserInfo] == nil)
        [self openAccountViewController:[CompleteOrderViewController class]];
    else
        [self performSegueWithIdentifier:@"CompleteOrder" sender:nil];
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

- (void) updateUI
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
            
            self.btnBottomButton.titleLabel.attributedText = attributedTitle;
            
            self.btnBottomButton.backgroundColor = [UIColor colorWithRed:135.0f / 255.0f green:176.0f / 255.0f blue:95.0f / 255.0f alpha:1.0f];
        }
        else
        {
            NSString *strTitle = [[AppStrings sharedInstance] getString:LOCATION_BUTTON_CONTINUE];
            [self.btnBottomButton setTitle:strTitle forState:UIControlStateNormal];
            
            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
            float spacing = 1.0f;
            [attributedTitle addAttribute:NSKernAttributeName
                                    value:@(spacing)
                                    range:NSMakeRange(0, [strTitle length])];
            
            self.btnBottomButton.titleLabel.attributedText = attributedTitle;
            
            self.btnBottomButton.backgroundColor = [UIColor colorWithRed:122.0f / 255.0f green:133.0f / 255.0f blue:145.0f / 255.0f alpha:1.0f];
        }
    }
    
    if ([[BentoShop sharedInstance] getCompletedBentoCount] > 0)
    {
        self.btnDelivery.enabled = YES;
    }
    else
    {
        self.btnDelivery.enabled = NO;
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
/*
    MKCoordinateSpan span = self.mapView.region.span;
    CLLocationCoordinate2D center = [self.mapView centerCoordinate];
    NSString *strBounds = [NSString stringWithFormat:@"%.6f,%.6f|%.6f,%.6f",
    center.latitude - (span.latitudeDelta / 2.0),
    center.longitude - (span.longitudeDelta / 2.0),
    center.latitude + (span.latitudeDelta / 2.0),
    center.longitude + (span.longitudeDelta / 2.0)];
 
    NSString *strRequest = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/geocode/json?address=%@&bounds=%@&key=%@", strSearch, strBounds, GOOGLE_API_KEY];
    strRequest = [strRequest stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    WebManager *webManager = [[WebManager alloc] init];
    
    [webManager AsyncRequest:strRequest method:GET parameters:nil success:^(MKNetworkOperation *networkOperation) {
        
        NSDictionary *result = (NSDictionary *)networkOperation.responseJSON;
        self.aryDisplay = [result objectForKey:@"results"];
        NSLog(@"%@", self.aryDisplay);
        [self.tvLocations reloadData];
        
        _isSearching = NO;
    } failure:^(MKNetworkOperation *errorOp, NSError *error) {
        
        self.aryDisplay = nil;
        [self.tvLocations reloadData];
        
        _isSearching = NO;
    } isJSON:NO];
*/
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
