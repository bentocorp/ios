
//
//  MyCLController.m
//  GpsPhoto
//
//  Created by 陈玉亮 on 12-7-27.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "MyCLController.h"

@implementation MyCLController

@synthesize locationManager;
@synthesize delegate;

- (id) init {
	self = [super init];
	if (self != nil) {
		self.locationManager = [[[CLLocationManager alloc] init] autorelease];
		self.locationManager.delegate = self; // send loc updates to myself
	}
	return self;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	[self.delegate locationUpdate:newLocation];
}


- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
	[self.delegate locationError:error];
}

- (void)dealloc {
    [super dealloc];
}

@end
