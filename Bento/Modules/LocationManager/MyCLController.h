//
//  MyCLController.h
//  GpsPhoto
//
//  Created by 陈玉亮 on 12-7-27.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@protocol MyCLControllerDelegate <NSObject>
@required
- (void)locationUpdate:(CLLocation *)location; 
- (void)locationError:(NSError *)error;
@end

@interface MyCLController : NSObject <CLLocationManagerDelegate>
{
	CLLocationManager *locationManager;
	id delegate;
}

@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, assign) id <MyCLControllerDelegate> delegate;

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation;

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error;

@end