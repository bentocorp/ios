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
#import "Mapbox.h"

@interface OrderStatusViewController () <MGLMapViewDelegate>

@property (nonatomic) MGLMapView *mapView;
@property (nonatomic) UIActivityIndicatorView *viewActivity;

@end

@implementation OrderStatusViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    [closeButton setImage:[UIImage imageNamed:@"nav_btn_close"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(onCloseButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    // line separator under nav bar
    UIView *longLineSepartor1 = [[UIView alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, 1)];
    longLineSepartor1.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
    [self.view addSubview:longLineSepartor1];
    
    /*-----------------------------------------------------------------------------------------------------*/
    
    /*-------------------------------------------MAPBOX----------------------------------------------------*/
    
    _mapView = [[MGLMapView alloc] initWithFrame:CGRectMake(0, 66, SCREEN_WIDTH, SCREEN_HEIGHT-66)];
    _mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // Set the map's bounds to Pisa, Italy
    MGLCoordinateBounds bounds = MGLCoordinateBoundsMake(CLLocationCoordinate2DMake(43.7115, 10.3725), CLLocationCoordinate2DMake(43.7318, 10.4222));
    [_mapView setVisibleCoordinateBounds:bounds];
    
    [self.view addSubview:_mapView];
    
    // Set the delegate property of our map view to self after instantiating it
    _mapView.delegate = self;
    
    // Initialize and add the marker annotation
    MGLPointAnnotation *pisa = [[MGLPointAnnotation alloc] init];
    pisa.coordinate = CLLocationCoordinate2DMake(43.72305, 10.396633);
    pisa.title = @"Leaning Tower of Pisa";
    
    MGLPointAnnotation *pisa2 = [[MGLPointAnnotation alloc] init];
    pisa2.coordinate = CLLocationCoordinate2DMake(43.72305, 10.4);
    pisa2.title = @"Leaning Tower of Pisa2";
    
    [_mapView addAnnotations:@[pisa, pisa2]];
    
    /*-----------------------------------------------------------------------------------------------------*/
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

// Allow markers callouts to show when tapped
- (BOOL)mapView:(MGLMapView *)mapView annotationCanShowCallout:(id <MGLAnnotation>)annotation
{
    return YES;
}

- (void)onCloseButton
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
