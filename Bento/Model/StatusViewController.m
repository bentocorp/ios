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

#define DEGREES_TO_RADIANS(degrees)((M_PI * degrees)/180)

@interface StatusViewController () <MKMapViewDelegate, SocketHandlerDelegate>

@property (nonatomic) SVPlacemark *placeInfo;
@property (nonatomic) CustomAnnotation *customerAnnotation;
@property (nonatomic) CustomAnnotation *driverAnnotation;
@property (nonatomic) CustomAnnotationView *driverAnnotationView;
@property (nonatomic) NSMutableArray *allAnnotations;

@end

@implementation StatusViewController
{
    int count;
    NSArray *lat2;
    NSArray *lng2;
    NSTimer *timer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self connectToNode];
    [self setupViews];
    
    lat2 = @[
             @"37.769002",
             @"37.767569",
             @"37.767232",
             @"37.767071",
             @"37.767003",
             @"37.766812",
             @"37.766675",
             @"37.766674",
             @"37.766425",
             @"37.764781"
             ];
    
    lng2 = @[
             @"-122.413448",
             @"-122.413330",
             @"-122.413287",
             @"-122.413336",
             @"-122.414473",
             @"-122.417718",
             @"-122.419709",
             @"-122.419845",
             @"-122.419822",
             @"-122.419688"
             ];
    
    
    timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(updateDriver) userInfo:nil repeats:YES];
    count = 0;
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
}

- (void)setupMap {
    self.mapView.delegate = self;
    self.mapView.mapType = MKMapTypeStandard;
    self.mapView.zoomEnabled = YES;
    self.mapView.scrollEnabled = YES;
    
    [SVGeocoder reverseGeocode:CLLocationCoordinate2DMake(self.lat, self.lng) completion:^(NSArray *placemarks, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (error == nil && placemarks.count > 0) {
            self.placeInfo = [placemarks firstObject];
            NSLog(@"placeinfo - %@", self.placeInfo);
            
            self.allAnnotations = [[NSMutableArray alloc] init];
            
            self.customerAnnotation= [[CustomAnnotation alloc] initWithTitle:@"Delivery Address"
                                                                    subtitle:[NSString stringWithFormat:@"%@ %@", self.placeInfo.subThoroughfare, self.placeInfo.thoroughfare]
                                                                  coordinate:CLLocationCoordinate2DMake(self.lat, self.lng)
                                                                        type:@"customer"];
            [self.allAnnotations addObject:self.customerAnnotation];
            
            self.driverAnnotation = [[CustomAnnotation alloc] initWithTitle:@"Server"
                                                                   subtitle:@""
                                                                 coordinate:CLLocationCoordinate2DMake([lat2[0] doubleValue], [lng2[0] doubleValue])
                                                                       type:@"driver"];
            [self.allAnnotations addObject:self.driverAnnotation];
            
            [self.mapView addAnnotations:self.allAnnotations];
            [self.mapView showAnnotations:self.allAnnotations animated:NO];
        }
        else {
            // handler error
        }
    }];
}

- (void)connectToNode {
    NSDictionary *userInfo = [[DataManager shareDataManager] getUserInfo];
    NSString *username = userInfo[@"email"];
    NSString *tokenString = [[DataManager shareDataManager] getAPIToken];
    [[SocketHandler sharedSocket] connectAndAuthenticate:username token:tokenString driverId:self.driverId];
    [SocketHandler sharedSocket].delegate = self;
}

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

- (void)updateDriver {
    
    count++;
    
    if (count == lat2.count-1) {
        [timer invalidate];
    }
    
    [UIView animateWithDuration:1 animations:^{
        CLLocation *start = [[CLLocation alloc] initWithLatitude:self.driverAnnotation.coordinate.latitude longitude:self.driverAnnotation.coordinate.longitude];
        CLLocation *end = [[CLLocation alloc] initWithLatitude:[lat2[count] doubleValue] longitude:[lng2[count] doubleValue]];
        double bearing = [start bearingToLocation:end];
        
        self.driverAnnotationView.imageView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(bearing));
    }];
    
    [UIView animateWithDuration:2 animations:^{
        self.driverAnnotation.coordinate = CLLocationCoordinate2DMake([lat2[count] doubleValue], [lng2[count] doubleValue]);
        [self.mapView showAnnotations:self.allAnnotations animated:YES];
    }];
}

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

- (void)closeSocket {
    [[SocketHandler sharedSocket] closeSocket];
}

- (void)socketHandlerDidConnect {
    [self getOrderHistory];
}

- (void)socketHandlerDidAuthenticate {
    
}

- (void)socketHandlerDidUpdateLocationWithLatitude:(float)lat andLongitude:(float)lng {
    
}

- (void)getOrderHistory {
    NSString *strRequest = [NSString stringWithFormat:@"/user/orderhistory?api_token=%@", [[DataManager shareDataManager] getAPIToken]];
    
    NSLog(@"/orderhistory strRequest - %@", strRequest);
    
    [[BentoShop sharedInstance] sendRequest:strRequest completion:^(id responseDic, NSError *error) {
        
        if (error == nil) {
            
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
        for (OrderHistoryItem *item in section.items) {
            [orderItems addObject:item];
        }
    }
    
    for (OrderHistoryItem *item in orderItems) {
        if (item.orderId == self.orderId) {
            switch (self.orderStatus) {
                case Assigned:
                    // handle assigned
                    
                    
                    return NO;
                case Enroute:
                    // handle enroute
                    
                    return NO;
                case Arrived:
                    // handle arrived
                    
                    return NO;
                default:
                    return YES; // order is rejected
            }
        }
    }
    
    return YES; // order does not exist
}

- (void)prepState {
    // turn off
    self.deliveryLabel.backgroundColor = [UIColor bento];
    
    // turn on
    self.prepLabel.backgroundColor = [UIColor bentoBrandGreen];
    self.num1Label.backgroundColor = [UIColor bentoBrandGreen];
}

- (void)deliveryState {
    
}

- (void)pickupState {
    
}

@end
