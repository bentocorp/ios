//
//  FiveHomeViewController.h
//  Bento
//
//  Created by Joseph Lau on 1/13/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

@interface FiveHomeViewController : BaseViewController

@property (weak, nonatomic) IBOutlet UIView *bgView;

@property (weak, nonatomic) IBOutlet UIButton *cartButton;
@property (weak, nonatomic) IBOutlet UILabel *countBadgeLabel;

@property (weak, nonatomic) IBOutlet UILabel *startingPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *etaLabel;

@property (weak, nonatomic) IBOutlet UIButton *pickerButton;
@property (weak, nonatomic) IBOutlet UIButton *finalizeButton;

@property (weak, nonatomic) IBOutlet UIView *dropDownView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *dropDownViewTopConstraint;

@property (weak, nonatomic) IBOutlet UIButton *fadedViewButton;
@property (weak, nonatomic) IBOutlet UIPickerView *orderAheadPickerView;

@property (weak, nonatomic) IBOutlet UILabel *asapMenuLabel;
@property (weak, nonatomic) IBOutlet UILabel *asapTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *asapDescriptionLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *asapDescriptionViewHeightConstraint;

@end
