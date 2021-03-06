//
//  FaqViewController.h
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    CONTENT_FAQ,
    CONTENT_PRIVACY,
    CONTENT_TERMS,
} CONTENT_TYPE;

@interface FaqViewController : UIViewController

@property (nonatomic) int contentType;
@property (nonatomic) NSString *strBottom;
@property (nonatomic) int *whatContentToDisplay;

@end
