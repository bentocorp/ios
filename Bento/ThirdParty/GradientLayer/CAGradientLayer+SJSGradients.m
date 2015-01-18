//
//  CAGradientLayer+SJSGradients.m
//  Sanjeet Suhag
//
//  Created by Sanjeet Suhag on 08/04/14.
//  Copyright (c) 2014 Sanjeet Suhag. All rights reserved.
//

#import "CAGradientLayer+SJSGradients.h"

#import <UIKit/UIKit.h>

@implementation CAGradientLayer (SJSGradients)

+ (CAGradientLayer *)blackGradientLayer
{
    // Defining the gradient colors
    UIColor *topColor = [UIColor clearColor];
    UIColor *bottomColor = [UIColor blackColor];
    
    // Defining the arrays to add to the gradients
    NSArray *gradientColors = [NSArray arrayWithObjects:(id)topColor.CGColor, (id)bottomColor.CGColor, nil];
    NSArray *gradientLocations = [NSArray arrayWithObjects:[NSNumber numberWithInt:0.0],[NSNumber numberWithInt:1.0], nil];
    
    // Defining the gradient layer
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = gradientColors;
    gradientLayer.locations = gradientLocations;
    
    return gradientLayer;
}

+ (CAGradientLayer *)redGradientLayer
{
    // Defining the gradient colors
    UIColor *topColor = [UIColor colorWithRed:252.0f/255.0f green:48.0f/255.0f blue:106.0f/255.0f alpha:1.0];
    UIColor *bottomColor = [UIColor colorWithRed:252.0f/255.0f green:90.0f/255.0f blue:99.0f/255.0f alpha:1.0];
    
    // Defining the arrays to add to the gradients
    NSArray *gradientColors = [NSArray arrayWithObjects:(id)topColor.CGColor, (id)bottomColor.CGColor, nil];
    NSArray *gradientLocations = [NSArray arrayWithObjects:[NSNumber numberWithInt:0.0],[NSNumber numberWithInt:1.0], nil];
    
    // Defining the gradient layer
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = gradientColors;
    gradientLayer.locations = gradientLocations;
    
    return gradientLayer;
}

+ (CAGradientLayer *)blueGradientLayer
{
    UIColor *topColor = [UIColor colorWithRed:109.0f/255.0f green:238.0f/255.0f blue:245.0f/255.0f alpha:1.0];
    UIColor *bottomColor = [UIColor colorWithRed:95.0f/255.0f green:201.0f/255.0f blue:249.0f/255.0f alpha:1.0];
    
    NSArray *gradientColors = [NSArray arrayWithObjects:(id)topColor.CGColor, (id)bottomColor.CGColor, nil];
    NSArray *gradientLocations = [NSArray arrayWithObjects:[NSNumber numberWithInt:0.0],[NSNumber numberWithInt:1.0], nil];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = gradientColors;
    gradientLayer.locations = gradientLocations;
    
    return gradientLayer;
}

+ (CAGradientLayer *)flavescentGradientLayer
{
    UIColor *topColor = [UIColor colorWithRed:1 green:0.92 blue:0.56 alpha:1];
    UIColor *bottomColor = [UIColor colorWithRed:0.18 green:0.18 blue:0.18 alpha:1];
    
    NSArray *gradientColors = [NSArray arrayWithObjects:(id)topColor.CGColor, (id)bottomColor.CGColor, nil];
    NSArray *gradientLocations = [NSArray arrayWithObjects:[NSNumber numberWithInt:0.0],[NSNumber numberWithInt:1.0], nil];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = gradientColors;
    gradientLayer.locations = gradientLocations;
    
    return gradientLayer;
}

+ (CAGradientLayer *)turquoiseGradientLayer
{
    UIColor *topColor = [UIColor colorWithRed:0.69 green:0.91 blue:0.93 alpha:1];
    UIColor *bottomColor = [UIColor colorWithRed:0.82 green:0.93 blue:0.7 alpha:1];
    
    NSArray *gradientColors = [NSArray arrayWithObjects:(id)topColor.CGColor, (id)bottomColor.CGColor, nil];
    NSArray *gradientLocations = [NSArray arrayWithObjects:[NSNumber numberWithInt:0.0],[NSNumber numberWithInt:1.0], nil];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = gradientColors;
    gradientLayer.locations = gradientLocations;
    
    return gradientLayer;
}

+ (CAGradientLayer *)pastelBlueGradientLayer
{
    UIColor *topColor = [UIColor colorWithRed:0.65 green:0.76 blue:0.82 alpha:1];
    UIColor *bottomColor = [UIColor colorWithRed:0.91 green:0.96 blue:0.98 alpha:1];
    
    NSArray *gradientColors = [NSArray arrayWithObjects:(id)topColor.CGColor, (id)bottomColor.CGColor, nil];
    NSArray *gradientLocations = [NSArray arrayWithObjects:[NSNumber numberWithInt:0.0],[NSNumber numberWithInt:1.0], nil];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = gradientColors;
    gradientLayer.locations = gradientLocations;
    
    return gradientLayer;
}

+ (CAGradientLayer *)tangerineGradientLayer
{
    UIColor *topColor = [UIColor colorWithRed:1 green:0.61 blue:0.5 alpha:1];
    UIColor *bottomColor = [UIColor colorWithRed:0.78 green:0.28 blue:0.15 alpha:1];
    
    NSArray *gradientColors = [NSArray arrayWithObjects:(id)topColor.CGColor, (id)bottomColor.CGColor, nil];
    NSArray *gradientLocations = [NSArray arrayWithObjects:[NSNumber numberWithInt:0.0],[NSNumber numberWithInt:1.0], nil];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = gradientColors;
    gradientLayer.locations = gradientLocations;
    
    return gradientLayer;
}

+ (CAGradientLayer *)whiteGradientLayer
{
    UIColor *topColor = [UIColor colorWithRed:0.81 green:0.81 blue:0.81 alpha:1];
    UIColor *bottomColor = [UIColor whiteColor];
    
    NSArray *gradientColors = [NSArray arrayWithObjects:(id)topColor.CGColor, (id)bottomColor.CGColor, nil];
    NSArray *gradientLocations = [NSArray arrayWithObjects:[NSNumber numberWithInt:0.0],[NSNumber numberWithInt:1.0], nil];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = gradientColors;
    gradientLayer.locations = gradientLocations;
    
    return gradientLayer;
}

+ (CAGradientLayer *)chocolateGradientLayer
{
    UIColor *topColor = [UIColor colorWithRed:0.89 green:0.97 blue:0.94 alpha:1];
    UIColor *bottomColor = [UIColor colorWithRed:0.35 green:0.28 blue:0.25 alpha:1];
    
    NSArray *gradientColors = [NSArray arrayWithObjects:(id)topColor.CGColor, (id)bottomColor.CGColor, nil];
    NSArray *gradientLocations = [NSArray arrayWithObjects:[NSNumber numberWithInt:0.0],[NSNumber numberWithInt:1.0], nil];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = gradientColors;
    gradientLayer.locations = gradientLocations;
    
    return gradientLayer;
}

+ (CAGradientLayer *)purpleGradientLayer
{
    UIColor *topColor = [UIColor colorWithRed:0.21 green:0.69 blue:0.97 alpha:1];
    UIColor *bottomColor = [UIColor colorWithRed:0.31 green:0.24 blue:0.42 alpha:1];
    
    NSArray *gradientColors = [NSArray arrayWithObjects:(id)topColor.CGColor, (id)bottomColor.CGColor, nil];
    NSArray *gradientLocations = [NSArray arrayWithObjects:[NSNumber numberWithInt:0.0],[NSNumber numberWithInt:1.0], nil];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = gradientColors;
    gradientLayer.locations = gradientLocations;
    
    return gradientLayer;
}

+ (CAGradientLayer *)yellowGradientLayer
{
    UIColor *topColor = [UIColor colorWithRed:0.93 green:0.87 blue:0.4 alpha:1];
    UIColor *bottomColor = [UIColor colorWithRed:0.93 green:0.62 blue:0.2 alpha:1];
    
    NSArray *gradientColors = [NSArray arrayWithObjects:(id)topColor.CGColor, (id)bottomColor.CGColor, nil];
    NSArray *gradientLocations = [NSArray arrayWithObjects:[NSNumber numberWithInt:0.0],[NSNumber numberWithInt:1.0], nil];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = gradientColors;
    gradientLayer.locations = gradientLocations;
    
    return gradientLayer;
}

+ (CAGradientLayer *)greenGradientLayer
{
    UIColor *topColor = [UIColor colorWithRed:0.83 green:1 blue:0.38 alpha:1];
    UIColor *bottomColor = [UIColor colorWithRed:0.58 green:0.91 blue:0.31 alpha:1];
    
    NSArray *gradientColors = [NSArray arrayWithObjects:(id)topColor.CGColor, (id)bottomColor.CGColor, nil];
    NSArray *gradientLocations = [NSArray arrayWithObjects:[NSNumber numberWithInt:0.0],[NSNumber numberWithInt:1.0], nil];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = gradientColors;
    gradientLayer.locations = gradientLocations;
    
    return gradientLayer;
}

@end
