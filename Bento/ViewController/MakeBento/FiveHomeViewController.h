//
//  FiveHomeViewController.h
//  Bento
//
//  Created by Joseph Lau on 1/13/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

typedef NS_ENUM(NSUInteger) {
    OnDemand,
    OrderAhead
} OrderMode;

@interface FiveHomeViewController : BaseViewController

@property (weak, nonatomic) IBOutlet UIView *bgView;

@property (weak, nonatomic) IBOutlet UIButton *cartButton;
@property (weak, nonatomic) IBOutlet UILabel *countBadgeLabel;

@property (weak, nonatomic) IBOutlet UILabel *startingPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *etaLabel;

@property (weak, nonatomic) IBOutlet UIButton *pickerButton;
@property (weak, nonatomic) IBOutlet UIButton *bottomButton;

@property (weak, nonatomic) IBOutlet UIView *dropDownView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *dropDownViewTopConstraint;

@property (weak, nonatomic) IBOutlet UIButton *fadedViewButton;
@property (weak, nonatomic) IBOutlet UIPickerView *orderAheadPickerView;

@property (weak, nonatomic) IBOutlet UILabel *asapMenuLabel;
@property (weak, nonatomic) IBOutlet UILabel *asapTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *asapDescriptionLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *asapViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *onDemandGreenView1;
@property (weak, nonatomic) IBOutlet UIView *onDemandGreenView2;
@property (weak, nonatomic) IBOutlet UIView *orderAheadGreenView1;
@property (weak, nonatomic) IBOutlet UIView *orderAheadGreenView2;

@property (weak, nonatomic) IBOutlet UIButton *enabledOnDemandButton;
@property (weak, nonatomic) IBOutlet UIButton *enabledOrderAheadButton;

@end
