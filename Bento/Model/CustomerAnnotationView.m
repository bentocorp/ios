//
//  CustomerAnnotationView.m
//  Bento
//
//  Created by Joseph Lau on 11/4/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import "CustomerAnnotationView.h"

@implementation CustomerAnnotationView

- (id)initWithAnnotationWithImage:(id<MKAnnotation>)annotation
                  reuseIdentifier:(NSString *)reuseIdentifier
              annotationViewImage:(UIImage *)image
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    self.image = image;
    
    return self;
}

@end
