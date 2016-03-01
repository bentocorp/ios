//
//  CLLocation+Bearing.h
//  Bento
//
//  Created by Joseph Lau on 2/29/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface CLLocation (Bearing)

- (double)bearingToLocation:(CLLocation *)destinationLocation;

@end
