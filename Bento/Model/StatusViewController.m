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
#import "CLLocation+Direction.h"
#import "CLLocation+Bearing.h"

#define DEGREES_TO_RADIANS(degrees)((M_PI * degrees)/180)

@interface StatusViewController () <MKMapViewDelegate>

@end

@implementation StatusViewController
{
    float diu;
    float diulei;
    float lomei;
    CustomAnnotation *driverAnnotation;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDictionary *userInfo = [[DataManager shareDataManager] getUserInfo];
    NSString *username = userInfo[@"email"];
    
    NSString *tokenString = [[DataManager shareDataManager] getAPIToken];
    
    [[SocketHandler sharedSocket] connectAndAuthenticate:username token:tokenString driverId:self.driverId];
    
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
    
    /*---*/
    
    //
    self.mapView.hidden = NO;
    
    // MAP VIEW
    self.mapView.delegate = self;
    self.mapView.mapType = MKMapTypeStandard;
    self.mapView.zoomEnabled = YES;
    self.mapView.scrollEnabled = YES;
    
    // should probably nil check
    
    // Annotations Array
    NSMutableArray *allAnnotations = [[NSMutableArray alloc] init];
    CustomAnnotation *customerAnnotation;
    
//    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:@"placeInfoData"];
//    NSMutableArray *placeInfoArray = [NSKeyedUnarchiver unarchiveObjectWithData:data];
//    for (int i = 0; i < placeInfoArray.count; i ++) {
//        
//        SVPlacemark *placeInfo = placeInfoArray[i];
//    
//        customerAnnotation = [[CustomAnnotation alloc] initWithTitle:@"Customer"
//                                                            subtitle:placeInfo.formattedAddress
//                                                          coordinate:placeInfo.location.coordinate
//                                                                type:@"customer"];
//        [allAnnotations addObject:customerAnnotation];
//    }
    
    customerAnnotation = [[CustomAnnotation alloc] initWithTitle:@"Customer"
                                                        subtitle:@"Hello im a customer"
                                                      coordinate:CLLocationCoordinate2DMake(37.779594, -122.429226)
                                                            type:@"customer"];
    [allAnnotations addObject:customerAnnotation];
    
    driverAnnotation = [[CustomAnnotation alloc] initWithTitle:@"Driver"
                                                      subtitle:@""
                                                    coordinate:CLLocationCoordinate2DMake(37.7545193, -122.440437)
                                                          type:@"driver"];
    [allAnnotations addObject:driverAnnotation];
    
    // Add annotations to map view
    [self.mapView showAnnotations:allAnnotations animated:YES];
    [self.mapView addAnnotations:allAnnotations];
    
    
    diu = 0.001;
    lomei = 37.7545193;
    diulei = -122.440437;
    
    [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateDriver) userInfo:nil repeats:YES];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    // set reuse identifier
    NSString *annotationIdentifier = @"CustomViewAnnotation";
    
    // not reusing because 1) there's not going to be many annotations to begin with, 2) it's causing the annotations to switch with each other
    //    CustomAnnotationView *customAnnotationView = (CustomAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
    
    CustomAnnotationView *customAnnotationView;
    
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
                                                                         annotationViewImage:[UIImage imageNamed:@"car"]];
        }
    }

    customAnnotationView.canShowCallout = YES;
    
    return customAnnotationView;
}

- (void)updateDriver {
    lomei += diu;
    diulei += diu;
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:driverAnnotation.coordinate.latitude longitude:driverAnnotation.coordinate.longitude];
    CLLocationDirection direction = [location directionFromLocation:driverAnnotation.coordinate];
    CGFloat radians = -direction / 180.0 * M_PI;
    
    //For Rotate Niddle
    CGFloat angle = RadiansToDegrees(radians);
    [self setLatLonForDistanceAndAngle];
    [self rotateArrowView:arrowView degrees:(angle + fltAngle)];
    
    [UIView animateWithDuration:5 animations:^{
        driverAnnotation.coordinate = CLLocationCoordinate2DMake(lomei, diulei);
    }];
}

- (void)rotateArrowView:(UIView *)view degrees:(CGFloat)degrees {
    CGAffineTransform transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(degrees));
    view.transform = transform;
}

// there will be a delegate method here from sockethandler didRecieveCoordianates

- (IBAction)backButtonPressed:(id)sender {
    [[SocketHandler sharedSocket] closeSocket];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)buildAnotherBentoButtonPressed:(id)sender {
    [[SocketHandler sharedSocket] closeSocket];
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
