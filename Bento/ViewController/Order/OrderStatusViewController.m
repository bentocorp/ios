//
//  OrderStatusViewController.m
//  Bento
//
//  Created by Joseph Lau on 9/23/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import "OrderStatusViewController.h"
#import "Mapbox.h"

@interface OrderStatusViewController () <MGLMapViewDelegate>

@property (nonatomic) MGLMapView *mapView;

@end

@implementation OrderStatusViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // initialize the map view
    self.mapView = [[MGLMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // set the map's center coordinate
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(38.894368, -77.036487)
                            zoomLevel:15
                             animated:NO];
    
    [self.view addSubview:self.mapView];
    
    self.mapView.delegate = self;
    
    // Declare the annotation `point` and set its coordinates, title, and subtitle
    MGLPointAnnotation *point = [[MGLPointAnnotation alloc] init];
    point.coordinate = CLLocationCoordinate2DMake(38.894368, -77.036487);
    point.title = @"Hello world!";
    point.subtitle = @"Welcome to The Ellipse.";
    
    // Add annotation `point` to the map
    [self.mapView addAnnotation:point];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
