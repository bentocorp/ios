//
//  StatusViewController.m
//  Bento
//
//  Created by Joseph Lau on 2/23/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import "StatusViewController.h"
#import "CustomAnnotation.h"
#import "CustomAnnotationView.h"
#import "SVGeocoder.h"
#import "NSUserDefaults+RMSaveCustomObject.h"
#import "SocketHandler.h"
#import "DataManager.h"
#import "CLLocation+Bearing.h"
#import "SVGeocoder.h"
#import "BentoShop.h"
#import "OrderHistorySection.h"
#import "OrderHistoryItem.h"
#import "UIColor+CustomColors.h"
#import "AppStrings.h"
#import <AFNetworking/AFNetworking.h>
#import "AFHTTPSessionManager.h"
#import "Step.h"

#define DEGREES_TO_RADIANS(degrees)((M_PI * degrees)/180)

@interface StatusViewController () <MKMapViewDelegate, SocketHandlerDelegate>

@property (nonatomic) SVPlacemark *placeInfo;
@property (nonatomic) CustomAnnotation *customerAnnotation;
@property (nonatomic) CustomAnnotation *driverAnnotation;
@property (nonatomic) CustomAnnotationView *driverAnnotationView;
@property (nonatomic) NSMutableArray *allAnnotations;

@property (nonatomic) NSMutableArray *steps;
@property (nonatomic) Step *currentStep;

@property (nonatomic) CLLocationCoordinate2D endLocation;
@property (nonatomic) NSString *routeDurationString;

@property (nonatomic) BOOL purposefullyDisconnected;

@end

@implementation StatusViewController
{
    CLLocation *currentLocation;
    
    NSInteger stepCount;
    NSInteger pathCoordinatesCount;
    NSTimer *timer;
    float speedFromPointToPoint;
    
    NSString *start;
    
    BOOL loadedOnce;
    
    
    NSTimer *timerForLastLocationUpdate;
    BOOL isReceivingLocation;
    NSInteger countSinceLastLocationUpdate;
    
    NSTimer *timerForGoogleMapsAPI;
    
    BOOL hasSetUpMap;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupViews];
    
    self.loadingHud.hidden = NO;
    [self.loadingHud startAnimating];
    
    [self getOrderHistory];
    
    [self connectToNode];
    
    self.steps = [[NSMutableArray alloc] init];
    
    isReceivingLocation = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getOrderHistory) name:USER_NOTIFICATION_UPDATED_MENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getOrderHistory) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getOrderHistory) name:@"enteredForeground" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectToNode) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeSocket) name:@"enteringBackground" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [timerForLastLocationUpdate invalidate];
    timerForLastLocationUpdate = nil;
    
    [timer invalidate];
    timer = nil;
}

- (void)setupViews {
    self.num1Label.layer.cornerRadius = 10;
    self.num1Label.layer.masksToBounds = YES;
    
    self.num2Label.layer.cornerRadius = 10;
    self.num2Label.layer.masksToBounds = YES;
    
    self.num3Label.layer.cornerRadius = 10;
    self.num3Label.layer.masksToBounds = YES;
    
    self.num4Label.layer.cornerRadius = 10;
    self.num4Label.layer.masksToBounds = YES;
    
    self.dotView1.layer.cornerRadius = 3;
    self.dotView1.layer.masksToBounds = YES;
    
    self.dotView2.layer.cornerRadius = 3;
    self.dotView2.layer.masksToBounds = YES;
    
    self.dotView3.layer.cornerRadius = 3;
    self.dotView3.layer.masksToBounds = YES;
    
    self.dotView4.layer.cornerRadius = 3;
    self.dotView4.layer.masksToBounds = YES;
    
    self.dotView5.layer.cornerRadius = 3;
    self.dotView5.layer.masksToBounds = YES;
    
    self.dotView6.layer.cornerRadius = 3;
    self.dotView6.layer.masksToBounds = YES;
    
    self.dotView7.layer.cornerRadius = 3;
    self.dotView7.layer.masksToBounds = YES;
    
    self.dotView8.layer.cornerRadius = 3;
    self.dotView8.layer.masksToBounds = YES;
    
    self.dotView9.layer.cornerRadius = 3;
    self.dotView9.layer.masksToBounds = YES;
}

- (void)setupMapWithDriverLat:(float)driverLat lng:(float)driverLng {
    [SVGeocoder reverseGeocode:self.endLocation completion:^(NSArray *placemarks, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (error == nil && placemarks.count > 0) {
            
            if (loadedOnce == NO) {
                loadedOnce = YES;
            
                self.placeInfo = [placemarks firstObject];
                
                self.allAnnotations = [[NSMutableArray alloc] init];
                
                self.customerAnnotation = [[CustomAnnotation alloc] initWithTitle:@"Delivery Address"
                                                                        subtitle:[NSString stringWithFormat:@"%@ %@", self.placeInfo.subThoroughfare, self.placeInfo.thoroughfare]
                                                                      coordinate:self.endLocation
                                                                            type:@"customer"];
                [self.allAnnotations addObject:self.customerAnnotation];
                

                self.driverAnnotation = [[CustomAnnotation alloc] initWithTitle:@"Joseph"
                                                                       subtitle:[NSString stringWithFormat:@"ETA: %@", self.routeDurationString]
                                                                     coordinate:CLLocationCoordinate2DMake(driverLat, driverLng)
                                                                           type:@"driver"];
                
                [self.allAnnotations addObject:self.driverAnnotation];
                
                [self.mapView addAnnotations:self.allAnnotations];
            
            
                [self.mapView selectAnnotation:self.driverAnnotation animated:YES];
                [self.mapView showAnnotations:self.allAnnotations animated:NO];
            }
            else {
                self.driverAnnotation.subtitle = [NSString stringWithFormat:@"ETA: %@", self.routeDurationString];
            }
        }
        else {
            // handler error
        }
    }];
}

# pragma mark Google Maps API

- (void)getRouteFromLastLocation {
    [timer invalidate];
    timer = nil;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.timeoutIntervalForRequest = 20;
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    // pass in last location
    NSString *api = @"https://maps.googleapis.com/maps/api/directions/";
    start = [NSString stringWithFormat:@"%f,%f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude];
    
    NSString *end = [NSString stringWithFormat:@"%f,%f", self.lat, self.lng];
    NSString *requestString = [NSString stringWithFormat:@"%@json?origin=%@&destination=%@&key=%@", api, start, end, GOOGLE_API_KEY];
    
    NSURL *URL = [NSURL URLWithString: requestString];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    [[manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self parseResponse:responseObject];
                
                NSLog(@"steps.count - %ld", (unsigned long)self.steps.count);
                
                [self setupMapWithDriverLat:currentLocation.coordinate.latitude lng:currentLocation.coordinate.longitude];
                
                stepCount = 0;
                
                if (isReceivingLocation == NO) {
                    [self loopThroughPathCoordinates];
                }
            });
        }
        else {
            // handle error
            NSLog(@"error - %@", error.debugDescription);
        }
    }] resume];
}

- (void)parseResponse:(NSDictionary *)response {
    NSArray *routes = response[@"routes"];
    NSDictionary *route = [routes firstObject];
    
    NSArray *legs = route[@"legs"];
    NSDictionary *leg = [legs firstObject];
    
    self.routeDurationString = leg[@"duration"][@"text"];
    
    NSLog(@"route duration string - %@", self.routeDurationString);
    
    NSArray *steps = leg[@"steps"];
    
    if (self.steps.count != 0) {
        [self.steps removeAllObjects];
    }
    
    for (NSDictionary *stepDic in steps) {
        if (stepDic) {
            Step *step = [[Step alloc] initWithDictionary:stepDic];
            [self.steps addObject:step];
        }
    }
    
    if (isReceivingLocation) {
        [self deliveryState];
    }
}

- (void)loopThroughPathCoordinates {
    if (stepCount < self.steps.count) {
        
        self.currentStep = self.steps[stepCount];
        
        pathCoordinatesCount = 0;
        
        speedFromPointToPoint = (float)self.currentStep.duration / (float)self.currentStep.pathCoordinates.count;

        dispatch_async(dispatch_get_main_queue(), ^{
            timer = [NSTimer scheduledTimerWithTimeInterval:speedFromPointToPoint target:self selector:@selector(updatePathCoordinatesCount) userInfo:nil repeats:YES];
            [timer fire];
        });
    }
}

- (void)updatePathCoordinatesCount {
    
    NSLog(@"speedFromPointToPoint - %f second(s)", speedFromPointToPoint);
    
    NSLog(@"step(%ld of %ld), pathCoordinate(%ld of %ld)", (long)stepCount, (unsigned long)self.steps.count, pathCoordinatesCount, (unsigned long)self.currentStep.pathCoordinates.count);
    
    if (pathCoordinatesCount < self.currentStep.pathCoordinates.count) {
        
        currentLocation = self.currentStep.pathCoordinates[pathCoordinatesCount];
        
        // turn fast (1 second)
        [UIView animateWithDuration:1 animations:^{
            CLLocation *stepStart = [[CLLocation alloc] initWithLatitude:self.driverAnnotation.coordinate.latitude longitude:self.driverAnnotation.coordinate.longitude];
            CLLocation *stepEnd = [[CLLocation alloc] initWithLatitude:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude];
            double bearing = [stepStart bearingToLocation:stepEnd];
            
            self.driverAnnotationView.imageView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(bearing));
        }];
        
        [UIView animateWithDuration:speedFromPointToPoint animations:^{
            self.driverAnnotation.coordinate = CLLocationCoordinate2DMake(currentLocation.coordinate.latitude, currentLocation.coordinate.longitude);
            [self.mapView showAnnotations:self.allAnnotations animated:YES];
        }];
    }
    else {
        [timer invalidate];
        stepCount++;
        [self loopThroughPathCoordinates];
    }
    
    pathCoordinatesCount++;
}

# pragma mark

- (void)updateLocation {
    [UIView animateWithDuration:1 animations:^{
        CLLocation *stepStart = [[CLLocation alloc] initWithLatitude:self.driverAnnotation.coordinate.latitude longitude:self.driverAnnotation.coordinate.longitude];
        CLLocation *stepEnd = [[CLLocation alloc] initWithLatitude:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude];
        double bearing = [stepStart bearingToLocation:stepEnd];
        
        self.driverAnnotationView.imageView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(bearing));
    }];
    
    [UIView animateWithDuration:5 animations:^{
        self.driverAnnotation.coordinate = CLLocationCoordinate2DMake(currentLocation.coordinate.latitude, currentLocation.coordinate.longitude);
        [self.mapView showAnnotations:self.allAnnotations animated:YES];
    }];
}

- (void)countSinceLastUpdate {
    countSinceLastLocationUpdate++;
//    NSLog(@"countSinceLastLocationUpdate - %ld", countSinceLastLocationUpdate);
    
    if (countSinceLastLocationUpdate >= 10) {
        isReceivingLocation = NO;
        
        if (timerForGoogleMapsAPI == nil) {
            [self getRouteFromLastLocation];
            timerForGoogleMapsAPI = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(getRouteFromLastLocation) userInfo:nil repeats:YES];
        }
    }
    else {
        isReceivingLocation = YES;
    }
}

#pragma mark MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    NSString *annotationIdentifier = @"CustomViewAnnotation";
    
    CustomAnnotationView *customerAnnotationView;
    
    CustomAnnotation *customAnnotation = (CustomAnnotation *)annotation;
    if ([customAnnotation.type isEqualToString:@"customer"]) {
        
        if (customerAnnotationView == nil) {
            customerAnnotationView = [[CustomAnnotationView alloc] initWithAnnotationWithImage:annotation
                                                                             reuseIdentifier:annotationIdentifier
                                                                         annotationViewImage:[UIImage imageNamed:@"location-64"]];
        }
        
        customerAnnotationView.canShowCallout = YES;
        
        return customerAnnotationView;
    }
    else if ([customAnnotation.type isEqualToString:@"driver"]) {
        
        if (self.driverAnnotationView == nil) {
            self.driverAnnotationView = [[CustomAnnotationView alloc] initWithAnnotationWithImage:annotation
                                                                             reuseIdentifier:annotationIdentifier
                                                                         annotationViewImage:[UIImage imageNamed:@"car"]];
        }
        
        self.driverAnnotationView.canShowCallout = YES;
        
        return self.driverAnnotationView;
    }
    
    return nil;
}

#pragma mark Navigation

- (IBAction)backButtonPressed:(id)sender {
    self.purposefullyDisconnected = YES;
    
    [self closeSocket];
    [self goBack];
}

- (IBAction)buildAnotherBentoButtonPressed:(id)sender {
    self.purposefullyDisconnected = YES;
    
    [self closeSocket];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)goBack {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark SocketHandlerDelegate

- (void)connectToNode {
    self.purposefullyDisconnected = NO;
    
    NSDictionary *userInfo = [[DataManager shareDataManager] getUserInfo];
    NSString *username = userInfo[@"email"];
    NSString *tokenString = [[DataManager shareDataManager] getAPIToken];
    [[SocketHandler sharedSocket] connectAndAuthenticate:username token:tokenString driverId:self.driverId];
    [SocketHandler sharedSocket].delegate = self;
}

- (void)socketHandlerDidConnect {
    
}

- (void)socketHandlerDidDisconnect {
    if (self.purposefullyDisconnected == false) {
        [self connectToNode];
    }
}

- (void)socketHandlerDidAuthenticate {
    if (self.orderStatus == Enroute) {
        [[SocketHandler sharedSocket] getLastSavedLocation];
    }
}

- (void)socketHandlerDidGetLastSavedLocation:(float)lat and:(float)lng {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.loadingHud != nil) {
            [self dismissHUD];
        }
        
        if (currentLocation == nil) {
            currentLocation = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
        }
        
        if (timerForGoogleMapsAPI == nil) {
            [self getRouteFromLastLocation];
            timerForGoogleMapsAPI = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(getRouteFromLastLocation) userInfo:nil repeats:YES];
        }
        else {
            [self deliveryState];
        }
    });
}

- (void)socketHandlerDidUpdateLocationWith:(float)lat and:(float)lng {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.orderStatus == Enroute) {
            
            [timerForGoogleMapsAPI invalidate];
            timerForGoogleMapsAPI = nil;
            
            countSinceLastLocationUpdate = 0;
            
            currentLocation = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
            
            [self updateLocation];
        }
    });
}

- (void)closeSocket {
    [[SocketHandler sharedSocket] closeSocket];
}

#pragma mark Order History

- (void)getOrderHistory {
    NSString *strRequest = [NSString stringWithFormat:@"/user/orderhistory?api_token=%@", [[DataManager shareDataManager] getAPIToken]];
    
    NSLog(@"/orderhistory strRequest - %@", strRequest);
    
    [[BentoShop sharedInstance] sendRequest:strRequest completion:^(id responseDic, NSError *error) {
        
        if (error == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
            
                if ([self shouldRemoveOrder:responseDic]) {
                    [self goBack];
                }
                
                if (self.orderStatus == Enroute) {
                    self.mapView.delegate = self;
                    self.mapView.mapType = MKMapTypeStandard;
                    self.mapView.zoomEnabled = YES;
                    self.mapView.scrollEnabled = YES;
                    
                    if (timerForLastLocationUpdate == nil) {
                        timerForLastLocationUpdate = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countSinceLastUpdate) userInfo:nil repeats:YES];
                    }
                }
                else {
                    [[SocketHandler sharedSocket] untrack];
                    
                    if (self.orderStatus == Assigned) {
                        [self prepState];
                    }
                    else if (self.orderStatus == Arrived) {
                        [self pickupState];
                    }
                    
                    [self dismissHUD];
                }
            });
        }
        else {
            // handle error
        }
    }];
}

- (void)dismissHUD {
    [self.loadingHud stopAnimating];
    self.loadingHud.hidden = YES;
}

- (BOOL)shouldRemoveOrder:(id)responseDic {
    NSMutableArray *orderHistoryArray = [[NSMutableArray alloc] init];
    for (NSDictionary *json in responseDic) {
        [orderHistoryArray addObject:[[OrderHistorySection alloc] initWithDictionary:json]];
    }
    
    NSMutableArray *orderItems = [[NSMutableArray alloc] init];
    for (OrderHistorySection *section in orderHistoryArray) {
        if ([section.sectionTitle isEqualToString:@"In Progress"]) {
            for (OrderHistoryItem *item in section.items) {
                [orderItems addObject:item];
            }
        }
    }
    
    for (OrderHistoryItem *item in orderItems) {
        if (item.orderId == self.orderId) {
            
            self.orderStatus = item.orderStatus;
            
            switch (self.orderStatus) {
                case Assigned:
                    return NO;
                case Enroute:
                    return NO;
                case Arrived:
                    return NO;
                default:
                    return YES;
            }
        }
    }
    
    return YES;
}

#pragma mark State Transitions

- (void)prepState {
    // turn on
    self.prepLabel.textColor = [UIColor bentoBrandGreen];
    self.num1Label.backgroundColor = [UIColor bentoBrandGreen];
    
    self.statusIconImageView.hidden = NO;
    self.descriptionTitleLabel.hidden = NO;
    self.descriptionLabel.hidden = NO;
    
    self.descriptionTitleLabel.text = [[AppStrings sharedInstance] getString:PREP_STATUS_TITLE];
    self.descriptionLabel.text = [[AppStrings sharedInstance] getString:PREP_STATUS_DESCRIPTION];
    
    // turn off
    self.deliveryLabel.textColor = [UIColor bentoOrderStatusGray];
    self.assemblyLabel.textColor = [UIColor bentoOrderStatusGray];
    self.pickupLabel.textColor = [UIColor bentoOrderStatusGray];
    
    self.num2Label.backgroundColor = [UIColor bentoOrderStatusGray];
    self.num3Label.backgroundColor = [UIColor bentoOrderStatusGray];
    self.num4Label.backgroundColor = [UIColor bentoOrderStatusGray];
    
    self.dotView1.backgroundColor = [UIColor bentoOrderStatusGray];
    self.dotView2.backgroundColor = [UIColor bentoOrderStatusGray];
    self.dotView3.backgroundColor = [UIColor bentoOrderStatusGray];
    self.dotView4.backgroundColor = [UIColor bentoOrderStatusGray];
    self.dotView5.backgroundColor = [UIColor bentoOrderStatusGray];
    self.dotView6.backgroundColor = [UIColor bentoOrderStatusGray];
    self.dotView7.backgroundColor = [UIColor bentoOrderStatusGray];
    self.dotView8.backgroundColor = [UIColor bentoOrderStatusGray];
    self.dotView9.backgroundColor = [UIColor bentoOrderStatusGray];
    
    self.mapView.hidden = YES;
}

- (void)deliveryState {
    
    if (hasSetUpMap == NO) {
        hasSetUpMap = YES;
        self.endLocation = CLLocationCoordinate2DMake(self.lat, self.lng);
    
        [self setupMapWithDriverLat:currentLocation.coordinate.latitude lng:currentLocation.coordinate.longitude];
    }
    
    // turn on
    self.prepLabel.textColor = [UIColor bentoBrandGreen];
    self.deliveryLabel.textColor = [UIColor bentoBrandGreen];
    self.num1Label.backgroundColor = [UIColor bentoBrandGreen];
    self.num2Label.backgroundColor = [UIColor bentoBrandGreen];
    
    self.dotView1.backgroundColor = [UIColor bentoBrandGreen];
    self.dotView2.backgroundColor = [UIColor bentoBrandGreen];
    self.dotView3.backgroundColor = [UIColor bentoBrandGreen];
    
    self.mapView.hidden = NO;
    
    // turn off
    self.assemblyLabel.textColor = [UIColor bentoOrderStatusGray];
    self.pickupLabel.textColor = [UIColor bentoOrderStatusGray];
    
    self.num3Label.backgroundColor = [UIColor bentoOrderStatusGray];
    self.num4Label.backgroundColor = [UIColor bentoOrderStatusGray];
    
    self.dotView4.backgroundColor = [UIColor bentoOrderStatusGray];
    self.dotView5.backgroundColor = [UIColor bentoOrderStatusGray];
    self.dotView6.backgroundColor = [UIColor bentoOrderStatusGray];
    self.dotView7.backgroundColor = [UIColor bentoOrderStatusGray];
    self.dotView8.backgroundColor = [UIColor bentoOrderStatusGray];
    self.dotView9.backgroundColor = [UIColor bentoOrderStatusGray];
    
    self.statusIconImageView.hidden = YES;
    self.descriptionTitleLabel.hidden = YES;
    self.descriptionLabel.hidden = YES;
}

- (void)pickupState {
    
    // turn on
    self.prepLabel.textColor = [UIColor bentoBrandGreen];
    self.deliveryLabel.textColor = [UIColor bentoBrandGreen];
    self.assemblyLabel.textColor = [UIColor bentoBrandGreen];
    self.pickupLabel.textColor = [UIColor bentoBrandGreen];
    
    self.num1Label.backgroundColor = [UIColor bentoBrandGreen];
    self.num2Label.backgroundColor = [UIColor bentoBrandGreen];
    self.num3Label.backgroundColor = [UIColor bentoBrandGreen];
    self.num4Label.backgroundColor = [UIColor bentoBrandGreen];
    
    self.dotView1.backgroundColor = [UIColor bentoBrandGreen];
    self.dotView2.backgroundColor = [UIColor bentoBrandGreen];
    self.dotView3.backgroundColor = [UIColor bentoBrandGreen];
    self.dotView4.backgroundColor = [UIColor bentoBrandGreen];
    self.dotView5.backgroundColor = [UIColor bentoBrandGreen];
    self.dotView6.backgroundColor = [UIColor bentoBrandGreen];
    self.dotView7.backgroundColor = [UIColor bentoBrandGreen];
    self.dotView8.backgroundColor = [UIColor bentoBrandGreen];
    self.dotView9.backgroundColor = [UIColor bentoBrandGreen];
    
    self.statusIconImageView.hidden = NO;
    self.descriptionTitleLabel.hidden = NO;
    self.descriptionLabel.hidden = NO;
    
    self.descriptionTitleLabel.text = [[AppStrings sharedInstance] getString:PICKUP_STATUS_TITLE];
    self.descriptionLabel.text = [[AppStrings sharedInstance] getString:PICKUP_STATUS_DESCRIPTION];
    
    // turn off
    self.mapView.hidden = YES;
}

@end
