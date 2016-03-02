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

#define DEGREES_TO_RADIANS(degrees)((M_PI * degrees)/180)

@interface StatusViewController () <MKMapViewDelegate>

@property (nonatomic) SVPlacemark *placeInfo;

@end

@implementation StatusViewController
{
    CustomAnnotation *driverAnnotation;
    CustomAnnotationView *driverAnnotationView;
    
    int count;
    NSArray *lat2;
    NSArray *lng2;
    
    NSMutableArray *allAnnotations;
    NSTimer *timer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    
    [self connectToNode];
    
    [self setupViews];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(updateDriver) userInfo:nil repeats:YES];
    count = 0;
    
    [SVGeocoder reverseGeocode:CLLocationCoordinate2DMake(self.lat, self.lng) completion:^(NSArray *placemarks, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (error == nil && placemarks.count > 0) {
            self.placeInfo = [placemarks firstObject];
            NSLog(@"placeinfo - %@", self.placeInfo);
            
            // Annotations Array
            allAnnotations = [[NSMutableArray alloc] init];
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
            
            customerAnnotation = [[CustomAnnotation alloc] initWithTitle:@"Delivery Address"
                                                                subtitle:[NSString stringWithFormat:@"%@ %@", self.placeInfo.subThoroughfare, self.placeInfo.thoroughfare]
                                                              coordinate:CLLocationCoordinate2DMake(self.lat, self.lng)
                                                                    type:@"customer"];
            [allAnnotations addObject:customerAnnotation];
            
            driverAnnotation = [[CustomAnnotation alloc] initWithTitle:@"Server"
                                                              subtitle:@""
                                                            coordinate:CLLocationCoordinate2DMake([lat2[0] doubleValue], [lng2[0] doubleValue])
                                                                  type:@"driver"];
            [allAnnotations addObject:driverAnnotation];
            
            [self.mapView addAnnotations:allAnnotations];
            [self.mapView showAnnotations:allAnnotations animated:NO];
        }
        else {
            
        }
    }];
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

- (void)connectToNode {
    NSDictionary *userInfo = [[DataManager shareDataManager] getUserInfo];
    NSString *username = userInfo[@"email"];
    NSString *tokenString = [[DataManager shareDataManager] getAPIToken];
    [[SocketHandler sharedSocket] connectAndAuthenticate:username token:tokenString driverId:self.driverId];
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
        
        if (driverAnnotationView == nil) {
            driverAnnotationView = [[CustomAnnotationView alloc] initWithAnnotationWithImage:annotation
                                                                             reuseIdentifier:annotationIdentifier
                                                                         annotationViewImage:[UIImage imageNamed:@"car"]];
            
            
        }
        
        driverAnnotationView.canShowCallout = YES;
        
        return driverAnnotationView;
    }
    
    return nil;
}

- (void)updateDriver {
    
    count++;
    
    if (count == lat2.count-1) {
        [timer invalidate];
    }
    
    [UIView animateWithDuration:1 animations:^{
        CLLocation *start = [[CLLocation alloc] initWithLatitude:driverAnnotation.coordinate.latitude longitude:driverAnnotation.coordinate.longitude];
        CLLocation *end = [[CLLocation alloc] initWithLatitude:[lat2[count] doubleValue] longitude:[lng2[count] doubleValue]];
        double bearing = [start bearingToLocation:end];
        
        driverAnnotationView.imageView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(bearing));
    }];
    
    [UIView animateWithDuration:2 animations:^{
        driverAnnotation.coordinate = CLLocationCoordinate2DMake([lat2[count] doubleValue], [lng2[count] doubleValue]);
        [self.mapView showAnnotations:allAnnotations animated:YES];
    }];
}

- (IBAction)backButtonPressed:(id)sender {
    [[SocketHandler sharedSocket] closeSocket];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)buildAnotherBentoButtonPressed:(id)sender {
    [[SocketHandler sharedSocket] closeSocket];
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
