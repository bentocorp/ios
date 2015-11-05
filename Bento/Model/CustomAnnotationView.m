//
//  CustomAnnotationView.m
//  Bento
//
//  Created by Joseph Lau on 11/4/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import "CustomAnnotationView.h"

@implementation CustomAnnotationView

- (id)initWithAnnotationWithImage:(id<MKAnnotation>)annotation
                  reuseIdentifier:(NSString *)reuseIdentifier
              annotationViewImage:(UIImage *)image
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    
    CGRect viewRect = CGRectMake(-20, -20, 40, 40);
    UIImageView* imageView = [[UIImageView alloc] initWithFrame:viewRect];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView = imageView;
    [self addSubview:imageView];
    
    self.image = image;
    
    return self;
}

@end
