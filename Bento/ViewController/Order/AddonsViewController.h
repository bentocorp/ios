//
//  AddonsViewController.h
//  Bento
//
//  Created by Joseph Lau on 11/17/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

@protocol AddonsViewControllerDelegate <NSObject>

@optional
- (void)addonsViewControllerDidTapOnFinalize:(BOOL)didTapOnFinalize;

@end

@interface AddonsViewController : BaseViewController

@property (nonatomic) id delegate;

@property (nonatomic) NSInteger autoScrollId;

@end
