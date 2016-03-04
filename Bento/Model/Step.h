//
//  Step.h
//  Bento
//
//  Created by Joseph Lau on 3/3/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface Step : NSObject

@property (nonatomic) CLLocationCoordinate2D startLocation;
@property (nonatomic) CLLocationCoordinate2D endLocation;
@property (nonatomic) NSMutableArray *pathCoordinates;
@property (nonatomic) NSInteger duration;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end

// int count = 0

// currentStep = steps[count]

// currentStep.pathCoordinates

// loop through currentStep.pathCoordinates with 1 second delay in between, animating from point to point while keeping count of the duration.

// pathCoordinatesCount = 0

// timer should repeatedly call a countPathCoordinates with 1 second delay

// if pathCoordinatesCount <= currentStep.duration -> update driver with currentStep.pathCoordinates[pathCoordinatesCount]

// 3 seconds to loop through 2 coordinates

// 53 / 44