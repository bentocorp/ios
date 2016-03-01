//
//  CLLocation+Direction.h
//
//  Created by Sheng on 3/4/14.
//

#import <CoreLocation/CoreLocation.h>

@interface CLLocation (Direction)
-(CLLocationDirection)directionFromLocation:(CLLocationCoordinate2D)coordinate;
@end
