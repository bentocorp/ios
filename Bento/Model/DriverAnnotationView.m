//
//  DriverAnnotationView.m
//  Bento
//
//  Created by Joseph Lau on 11/3/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import "DriverAnnotationView.h"

@implementation DriverAnnotationView

- (id)initWithAnnotationWithImage:(id<MKAnnotation>)annotation
                  reuseIdentifier:(NSString *)reuseIdentifier
              annotationViewImage:(UIImage *)image
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    self.image = image;
    
    return self;
}

@end
