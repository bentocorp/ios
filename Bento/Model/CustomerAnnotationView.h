//
//  CustomerAnnotationView.h
//  Bento
//
//  Created by Joseph Lau on 11/4/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface CustomerAnnotationView : MKAnnotationView

- (id)initWithAnnotationWithImage:(id<MKAnnotation>)annotation
                  reuseIdentifier:(NSString *)reuseIdentifier
              annotationViewImage:(UIImage *)image;

@end
