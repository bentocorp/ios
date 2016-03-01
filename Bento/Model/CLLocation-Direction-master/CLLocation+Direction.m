//
//  CLLocation+Direction.m
//
//  Created by Sheng on 3/4/14.
//

#import "CLLocation+Direction.h"

#define RadiansToDegrees(rad) ( rad * 180.0 / M_PI)
#define DegreesToRadians(deg) ( deg * M_PI / 180.0)

@implementation CLLocation (Direction)

-(CLLocationDirection)directionFromLocation:(CLLocationCoordinate2D)coordinate {
    //Calculate angle between two points taken from http://www.movable-type.co.uk/scripts/latlong.html
    
    double lat1 = DegreesToRadians(self.coordinate.latitude);
    double lon1 = DegreesToRadians(self.coordinate.longitude);
    
    double lat2 = DegreesToRadians(coordinate.latitude);
    double lon2 = DegreesToRadians(coordinate.longitude);
    
    double dLon = lon2 - lon1;
    
    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    
    double brng = RadiansToDegrees(atan2(y, x));
    
    double bearing = ((int)(brng + 360) % 360);
    return bearing;
}

@end
