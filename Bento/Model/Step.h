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
@property (nonatomic) int duration;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
