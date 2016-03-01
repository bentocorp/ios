//
//  CLLocation+Bearing.m
//  Bento
//
//  Created by Joseph Lau on 2/29/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import "CLLocation+Bearing.h"

double DegreesToRadians(double degrees) {return degrees * M_PI / 180.0;};
double RadiansToDegrees(double radians) {return radians * 180.0/M_PI;};

@implementation CLLocation (Bearing)

-(double) bearingToLocation:(CLLocation *) destinationLocation {
    
    double lat1 = DegreesToRadians(self.coordinate.latitude);
    double lon1 = DegreesToRadians(self.coordinate.longitude);
    
    double lat2 = DegreesToRadians(destinationLocation.coordinate.latitude);
    double lon2 = DegreesToRadians(destinationLocation.coordinate.longitude);
    
    double dLon = lon2 - lon1;
    
    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    double radiansBearing = atan2(y, x);
    
    if(radiansBearing < 0.0) {
        radiansBearing += 2*M_PI;
    }
    
    return RadiansToDegrees(radiansBearing);
}

@end
