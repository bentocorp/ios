//
//  HomeViewController.h
//  Bento
//
//  Created by Joseph Lau on 1/8/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

@interface HomeViewController : BaseViewController

@property (weak, nonatomic) IBOutlet UIButton *cartButton;
@property (weak, nonatomic) IBOutlet UILabel *countBadgeLabel;

@property (weak, nonatomic) IBOutlet UILabel *startingPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *etaLabel;

@property (weak, nonatomic) IBOutlet UIButton *pickerButton;
@property (weak, nonatomic) IBOutlet UIButton *bottomButton;

@end
