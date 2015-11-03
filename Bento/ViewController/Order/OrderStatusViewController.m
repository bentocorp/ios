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
#import "Annotation.h"
#import "SVGeocoder.h"
#import "NSUserDefaults+RMSaveCustomObject.h"

@interface OrderStatusViewController () <MKMapViewDelegate>

@property (nonatomic) MKMapView *mapView;

@end

// SF Coordinates
#define SF_LAT 37.7545193;
#define SF_LNG -122.440437;

// Span
#define THE_SPAN 0.15f;

@implementation OrderStatusViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    
//    // Center
//    CLLocationCoordinate2D center;
//    center.latitude = SF_LAT;
//    center.longitude = SF_LNG;
//    
//    // Span
//    MKCoordinateSpan span;
//    span.latitudeDelta = THE_SPAN;
//    span.longitudeDelta = THE_SPAN;
    
//    // Set mapview region
//    MKCoordinateRegion sfRegion;
//    sfRegion.center = center;
//    sfRegion.span = span;
//    [self.mapView setRegion:sfRegion animated:YES];
    
    
    // Annotation
    SVPlacemark *placeMark = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"];
    
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = placeMark.location.coordinate;
    annotation.title = @"Delivery Address";
    annotation.subtitle = placeMark.formattedAddress;
    
    MKPointAnnotation *annotation2 = [[MKPointAnnotation alloc] init];
    annotation2.coordinate = CLLocationCoordinate2DMake(37.7545193, -122.440437);
    
    NSMutableArray *annotations = [[NSMutableArray alloc] init];
    [annotations addObject:annotation];
    [annotations addObject:annotation2];
    
    // Add annotation to mapview
    // Map View
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 66, SCREEN_WIDTH, SCREEN_HEIGHT-66)];
    self.mapView.mapType = MKMapTypeStandard;
    self.mapView.zoomEnabled = YES;
    self.mapView.scrollEnabled = YES;
    [self.mapView showAnnotations:annotations animated:YES];
    [self.mapView addAnnotations:annotations];
    [self.view addSubview: self.mapView];
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
