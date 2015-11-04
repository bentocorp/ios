//
//  DriverAnnotationView.h
//  Bento
//
//  Created by Joseph Lau on 11/3/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface DriverAnnotationView : MKAnnotationView

- (id)initWithAnnotationWithImage:(id<MKAnnotation>)annotation
                  reuseIdentifier:(NSString *)reuseIdentifier
              annotationViewImage:(UIImage *)image;

@end
