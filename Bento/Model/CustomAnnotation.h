//
//  CustomAnnotation.h
//  Bento
//
//  Created by Joseph Lau on 11/4/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface CustomAnnotation : NSObject <MKAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *type;

- (id)initWithTitle:(NSString *)title
           subtitle:(NSString *)subtitle
         coordinate:(CLLocationCoordinate2D)coordinate
               type:(NSString *)type;

@end
