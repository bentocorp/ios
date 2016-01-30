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

@property (weak, nonatomic) IBOutlet UIView *etaBannerView;
@property (weak, nonatomic) IBOutlet UILabel *startingPriceLabel;
@property (weak, nonatomic) IBOutlet UIView *etaBannerDivider;
@property (weak, nonatomic) IBOutlet UILabel *etaLabel;
@property (weak, nonatomic) IBOutlet UILabel *previewLabel;

@property (weak, nonatomic) IBOutlet UIButton *pickerButton;
@property (weak, nonatomic) IBOutlet UIButton *bottomButton;

@property (weak, nonatomic) IBOutlet UIView *dropDownView;
@property (weak, nonatomic) IBOutlet UIButton *fadedViewButton;

@property (weak, nonatomic) IBOutlet UILabel *asapMenuLabel;
@property (weak, nonatomic) IBOutlet UILabel *asapDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *orderAheadTitleLabel;

@property (weak, nonatomic) IBOutlet UIView *onDemandView;
@property (weak, nonatomic) IBOutlet UIView *orderAheadView;
@property (weak, nonatomic) IBOutlet UIPickerView *orderAheadPickerView;
@property (weak, nonatomic) IBOutlet UIImageView *orderAheadCheckMarkImageView;
@property (weak, nonatomic) IBOutlet UIImageView *onDemandCheckMarkImageView;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *dropDownViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *onDemandViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *orderAheadViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *orderAheadPickerContainerViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *doneButtonWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *doneButtonHeightConstraint;

@property (weak, nonatomic) IBOutlet UIButton *enabledOnDemandButton;
@property (weak, nonatomic) IBOutlet UIButton *enabledOrderAheadButton;

// either menu from menu/date or selected menu from order-ahead menu
// logic for finding the right menu to use will be set in implementation file
@property (nonatomic) NSDictionary *selectedMenu;

@property (nonatomic) NSInteger selectedOrderAheadTimeRangeIndex;

@end
