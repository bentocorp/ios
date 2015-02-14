//
//  EnterCreditCardViewController.h
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "STPCard.h"

@protocol EnterCreditCardViewControllerDelegate

- (void) setCardInfo:(STPCard *)cardInfo;

@end

@interface EnterCreditCardViewController : UIViewController

@property (nonatomic, assign) id<EnterCreditCardViewControllerDelegate> delegate;

@end
