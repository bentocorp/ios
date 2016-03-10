//
//  StatusViewController.h
//  Bento
//
//  Created by Joseph Lau on 2/23/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "OrderHistoryItem.h"

@interface StatusViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UIImageView *statusIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *buildAnotherBentoButton;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (weak, nonatomic) IBOutlet UILabel *num1Label;
@property (weak, nonatomic) IBOutlet UILabel *num2Label;
@property (weak, nonatomic) IBOutlet UILabel *num3Label;
@property (weak, nonatomic) IBOutlet UILabel *num4Label;

@property (weak, nonatomic) IBOutlet UILabel *prepLabel;
@property (weak, nonatomic) IBOutlet UILabel *deliveryLabel;
@property (weak, nonatomic) IBOutlet UILabel *assemblyLabel;
@property (weak, nonatomic) IBOutlet UILabel *pickupLabel;

@property (weak, nonatomic) IBOutlet UIView *dotView1;
@property (weak, nonatomic) IBOutlet UIView *dotView2;
@property (weak, nonatomic) IBOutlet UIView *dotView3;
@property (weak, nonatomic) IBOutlet UIView *dotView4;
@property (weak, nonatomic) IBOutlet UIView *dotView5;
@property (weak, nonatomic) IBOutlet UIView *dotView6;
@property (weak, nonatomic) IBOutlet UIView *dotView7;
@property (weak, nonatomic) IBOutlet UIView *dotView8;
@property (weak, nonatomic) IBOutlet UIView *dotView9;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingHud;

@property (nonatomic) NSString *orderId;
@property (nonatomic) OrderStatus orderStatus;
@property (nonatomic) NSString *driverId;
@property (nonatomic) NSString *driverName;
@property (nonatomic) float lat;
@property (nonatomic) float lng;

@end
