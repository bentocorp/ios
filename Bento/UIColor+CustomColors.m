//
//  UIColor+CustomColors.m
//  Bento
//
//  Created by Joseph Lau on 8/27/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "UIColor+CustomColors.h"

@implementation UIColor (CustomColors)

+ (UIColor *)bentoBrandGreen {
    return [UIColor colorWithRed:135.0f / 255.0f green:178.0f / 255.0f blue:96.0f / 255.0f alpha:1.0f];
};

+ (UIColor *)bentoTitleGray {
    return [UIColor colorWithRed:0.341f green:0.376f blue:0.439f alpha:1.0f];
};

+ (UIColor *)bentoButtonGray {
    return [UIColor colorWithRed:122.0f / 255.0f green:133.0f / 255.0f blue:146.0f / 255.0f alpha:1.0f];
}

+ (UIColor *)bentoBackgroundGray {
    return [UIColor colorWithRed:0.914f green:0.925f blue:0.925f alpha:1.0f];
}

+ (UIColor *)bentoErrorTextOrange {
    return [UIColor colorWithRed:233.0f / 255.0f green:114.0f / 255.0f blue:2.0f / 255.0f alpha:1.0f];
};

+ (UIColor *)bentoCorrectTextGray {
    return [UIColor colorWithRed:109.0f / 255.0f green:117.0f / 255.0f blue:131.0f / 255.0f alpha:1.0f];
};

+ (UIColor *)bentoGradient1 {
    return [UIColor colorWithRed:156.f/255.f green:211.f/255.f blue:101.f/255.f alpha:0.8f];
}

+ (UIColor *)bentoGradient2 {
    return [UIColor colorWithRed:125.f/255.f green:170.f/255.f blue:82.f/255.f alpha:0.8f];
}

@end
