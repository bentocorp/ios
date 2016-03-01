//
//  CustomAnnotation.m
//  Bento
//
//  Created by Joseph Lau on 11/4/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import "CustomAnnotation.h"
#import "CLLocation+Bearing.h"

@implementation CustomAnnotation

- (id)initWithTitle:(NSString *)title
           subtitle:(NSString *)subtitle
         coordinate:(CLLocationCoordinate2D)coordinate
               type:(NSString *)type {
    self = [super init];
    
    if (self) {
        _title = title;
        _subtitle = subtitle;
        _coordinate = coordinate;
        _type = type;
    }
    
    return self;
}

@end
