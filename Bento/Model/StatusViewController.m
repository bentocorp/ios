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

@property (nonatomic) CLLocationCoordinate2D startLocation;
@property (nonatomic) CLLocationCoordinate2D endLocation;
@property (nonatomic) NSString *routeDurationString;

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
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // uncomment this later
    [self connectToNode];
    [self setupViews];
    
    self.steps = [[NSMutableArray alloc] init];
    
//    [self getRouteFromLastLocation];
//    [NSTimer scheduledTimerWithTimeInterval:3*60 target:self selector:@selector(getRouteFromLastLocation) userInfo:nil repeats:YES];
}

- (void)getRouteFromLastLocation {
    [timer invalidate];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.timeoutIntervalForRequest = 20;
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    // pass in last location
    NSString *api = @"https://maps.googleapis.com/maps/api/directions/";
    if (start == nil || [start isEqualToString:@""]) {
        start = [NSString stringWithFormat:@"%f,%f", 37.774821, -122.396259];
    }
    else {
        start = [NSString stringWithFormat:@"%F,%f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude];
    }
    NSString *end = [NSString stringWithFormat:@"%f,%f", 37.764199, -122.391316];
    NSString *requestString = [NSString stringWithFormat:@"%@json?origin=%@&destination=%@&key=%@", api, start, end, GOOGLE_API_KEY];
    
    NSURL *URL = [NSURL URLWithString: requestString];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    [[manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error == nil) {
            [self parseResponse:responseObject];
        
            NSLog(@"steps.count - %ld", (unsigned long)self.steps.count);
            
            [self setupViews];
            
            stepCount = 0;
            [self loopThroughPathCoordinates];
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
    
    self.startLocation = CLLocationCoordinate2DMake([leg[@"start_location"][@"lat"] floatValue], [leg[@"start_location"][@"lng"] floatValue]);
    self.endLocation = CLLocationCoordinate2DMake([leg[@"end_location"][@"lat"] floatValue], [leg[@"end_location"][@"lng"] floatValue]);
    self.routeDurationString = leg[@"duration"][@"text"];
    
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
}

- (void)loopThroughPathCoordinates {
    if (stepCount < self.steps.count) {
        
        self.currentStep = self.steps[stepCount];
        
        pathCoordinatesCount = 0;
        
        speedFromPointToPoint = (float)self.currentStep.duration / (float)self.currentStep.pathCoordinates.count;
        
        timer = [NSTimer scheduledTimerWithTimeInterval:speedFromPointToPoint target:self selector:@selector(updatePathCoordinatesCount) userInfo:nil repeats:YES];
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
//            [self.mapView showAnnotations:self.allAnnotations animated:YES];
        }];
    }
    else {
        [timer invalidate];
        stepCount++;
        [self loopThroughPathCoordinates];
    }
    
    pathCoordinatesCount++;
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
    
    [self setupMap];
    self.mapView.hidden = NO; // delete later
}

- (void)setupMap {
    self.mapView.delegate = self;
    self.mapView.mapType = MKMapTypeStandard;
    self.mapView.zoomEnabled = YES;
    self.mapView.scrollEnabled = YES;
    
    [SVGeocoder reverseGeocode:CLLocationCoordinate2DMake(self.lat, self.lng) completion:^(NSArray *placemarks, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (error == nil && placemarks.count > 0) {
            self.placeInfo = [placemarks firstObject];
//            NSLog(@"placeinfo - %@", self.placeInfo);
            
            self.allAnnotations = [[NSMutableArray alloc] init];
            
            
            
            self.customerAnnotation = [[CustomAnnotation alloc] initWithTitle:@"Delivery Address"
                                                                    subtitle:[NSString stringWithFormat:@"%@ %@", self.placeInfo.subThoroughfare, self.placeInfo.thoroughfare]
                                                                  coordinate:self.endLocation
                                                                        type:@"customer"];
            [self.allAnnotations addObject:self.customerAnnotation];
            
            self.driverAnnotation = [[CustomAnnotation alloc] initWithTitle:@"Joseph"
                                                                   subtitle:[NSString stringWithFormat:@"ETA: %@", self.routeDurationString]
                                                                 coordinate:self.startLocation
                                                                       type:@"driver"];
            [self.allAnnotations addObject:self.driverAnnotation];
            
            [self.mapView addAnnotations:self.allAnnotations];
            
            [self.mapView selectAnnotation:self.driverAnnotation animated:YES];
            
            if (loadedOnce == NO) {
                loadedOnce = YES;
                [self.mapView showAnnotations:self.allAnnotations animated:NO];
            }
        }
        else {
            // handler error
        }
    }];
}

#pragma mark MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    // set reuse identifier
    NSString *annotationIdentifier = @"CustomViewAnnotation";
    
    // not reusing because 1) there's not going to be many annotations to begin with, 2) it's causing the annotations to switch with each other
    //    CustomAnnotationView *customAnnotationView = (CustomAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
    
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
    [self closeSocket];
    [self goBack];
}

- (IBAction)buildAnotherBentoButtonPressed:(id)sender {
    [self closeSocket];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)goBack {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark SocketHandlerDelegate

- (void)connectToNode {
    NSDictionary *userInfo = [[DataManager shareDataManager] getUserInfo];
    NSString *username = userInfo[@"email"];
    NSString *tokenString = [[DataManager shareDataManager] getAPIToken];
    [[SocketHandler sharedSocket] connectAndAuthenticate:username token:tokenString driverId:self.driverId];
    [SocketHandler sharedSocket].delegate = self;
}

- (void)socketHandlerDidConnect {
    
}

- (void)socketHandlerDidAuthenticate {
    [self getOrderHistory];
}

- (void)socketHandlerDidUpdateLocationWithLatitude:(float)lat andLongitude:(float)lng {
    
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

            // uncomment this later
            if ([self shouldRemoveOrder:responseDic]) {
                [self goBack];
            }
        }
        else {
            // handle error
        }
    }];
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
            switch (self.orderStatus) {
                case Assigned:
                    [self prepState];
                    return NO;
                case Enroute:
                    [self deliveryState];
                    return NO;
                case Arrived:
                    [self pickupState];
                    return NO;
                default:
                    return YES; // order is rejected
            }
        }
    }
    
    return YES; // order does not exist
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
    // turn on
    self.prepLabel.textColor = [UIColor bentoBrandGreen];
    self.deliveryLabel.textColor = [UIColor bentoBrandGreen];
    self.num1Label.backgroundColor = [UIColor bentoBrandGreen];
    self.num2Label.backgroundColor = [UIColor bentoBrandGreen];
    self.num3Label.backgroundColor = [UIColor bentoBrandGreen];
    
    self.mapView.hidden = NO;
    
    // turn off
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
