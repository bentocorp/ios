//
//  OrderStatusViewController.m
//  Bento
//
//  Created by Joseph Lau on 9/23/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#import "OrderStatusViewController.h"
#import "UIColor+CustomColors.h"
#import <MapKit/MapKit.h>
#import "SVGeocoder.h"
#import "NSUserDefaults+RMSaveCustomObject.h"

#import "CustomAnnotation.h"
#import "CustomAnnotationView.h"

@interface OrderStatusViewController () <MKMapViewDelegate>

@property (nonatomic) MKMapView *mapView;

@end

@implementation OrderStatusViewController {
    float diu;
    float diulei;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    diu = 0.001;
    diulei = -122.440437;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    /*-----------------------------------------------------------------------------------------------------*/
    
    // navigation bar color
    UIView *navigationBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 65)];
    navigationBarView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navigationBarView];
    
    // title label
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 2 - 110, 20, 220, 45)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    titleLabel.textColor = [UIColor bentoTitleGray];
    titleLabel.text = @"Order Status";
    [self.view addSubview:titleLabel];
    
    // back button
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 50, 45)];
    [closeButton setImage:[UIImage imageNamed:@"nav_btn_back"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(onCloseButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    // line separator under nav bar
    UIView *longLineSepartor1 = [[UIView alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, 1)];
    longLineSepartor1.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
    [self.view addSubview:longLineSepartor1];
    
    /*-----------------------------------------------------------------------------------------------------*/
    
    // Map View
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 66, SCREEN_WIDTH, SCREEN_HEIGHT - 66)];
    self.mapView.delegate = self;
    self.mapView.mapType = MKMapTypeStandard;
    self.mapView.zoomEnabled = YES;
    self.mapView.scrollEnabled = YES;
    [self.view addSubview: self.mapView];
    
    // Annotations
    SVPlacemark *placeMark = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"];

    CustomAnnotation *customerAnnotation = [[CustomAnnotation alloc] initWithTitle:@"Customer"
                                                                          subtitle:placeMark.formattedAddress
                                                                        coordinate:placeMark.location.coordinate
                                                                              type:@"customer"];
    
    CustomAnnotation *driverAnnotation = [[CustomAnnotation alloc] initWithTitle:@"Driver"
                                                                        subtitle:@""
                                                                      coordinate:CLLocationCoordinate2DMake(37.7545193, -122.440437)
                                                                            type:@"driver"];
    
    
    // Annotations Array
    NSMutableArray *allAnnotations = [[NSMutableArray alloc] init];
    [allAnnotations addObject:customerAnnotation];
    [allAnnotations addObject:driverAnnotation];
    
    // Add annotations to map view
    [self.mapView showAnnotations:allAnnotations animated:YES];
    [self.mapView addAnnotations:allAnnotations];
    
//    [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(updateDriver) userInfo:nil repeats:YES];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    // set reuse identifier
    NSString *annotationIdentifier = @"CustomViewAnnotation";
    
    CustomAnnotationView *customAnnotationView = (CustomAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
    
    CustomAnnotation *customAnnotation = (CustomAnnotation *)annotation;
    if ([customAnnotation.type isEqualToString:@"customer"]) {
        
        if (customAnnotationView == nil) {
            customAnnotationView = [[CustomAnnotationView alloc] initWithAnnotationWithImage:annotation
                                                                             reuseIdentifier:annotationIdentifier
                                                                         annotationViewImage:[UIImage imageNamed:@"location-64"]];
        }
    }
    else if ([customAnnotation.type isEqualToString:@"driver"]) {
        
        if (customAnnotationView == nil) {
            customAnnotationView = [[CustomAnnotationView alloc] initWithAnnotationWithImage:annotation
                                                                             reuseIdentifier:annotationIdentifier
                                                                         annotationViewImage:[UIImage imageNamed:@"in-transit-64"]];
        }
    }
    
    customAnnotationView.canShowCallout = YES;
    
    return customAnnotationView;
}

- (void)updateDriver {
    diulei += diu;
//    self.driverAnnotationView.annotation = CLLocationCoordinate2DMake(37.7545193, diulei);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

// there will be a delegate method here from sockethandler didRecieveCoordianates

#pragma mark Dismiss View
- (void)onCloseButton {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
