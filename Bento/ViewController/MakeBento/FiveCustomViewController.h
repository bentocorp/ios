//
//  FiveCustomViewController.h
//  Bento
//
//  Created by Joseph Lau on 1/13/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

@protocol FiveCustomViewControllerDelegate <NSObject>

- (void)customVCAddMainButtonPressed:(id)sender;
- (void)customVCAddSideDish1Pressed:(id)sender;
- (void)customVCAddSideDish2Pressed:(id)sender;
- (void)customVCAddSideDish3Pressed:(id)sender;
- (void)customVCAddSideDish4Pressed:(id)sender;
- (void)customVCBuildButtonPressed:(id)sender;
- (void)customVCViewAddonsButtonPressed:(id)sender;

@end

@interface FiveCustomViewController : BaseViewController

@property (weak, nonatomic) IBOutlet UIView *dishBGView;

@property (weak, nonatomic) IBOutlet UIView *mainDishView;
@property (weak, nonatomic) IBOutlet UIView *sideDish1View;
@property (weak, nonatomic) IBOutlet UIView *sideDish2View;
@property (weak, nonatomic) IBOutlet UIView *sideDish3View;
@property (weak, nonatomic) IBOutlet UIView *sideDish4View;

@property (weak, nonatomic) IBOutlet UIImageView *mainDishImageView;
@property (weak, nonatomic) IBOutlet UIImageView *sideDish1ImageView;
@property (weak, nonatomic) IBOutlet UIImageView *sideDish2Imageview;
@property (weak, nonatomic) IBOutlet UIImageView *sideDish3ImageView;
@property (weak, nonatomic) IBOutlet UIImageView *sideDish4ImageView;


@property (weak, nonatomic) IBOutlet UILabel *mainDishLabel;
@property (weak, nonatomic) IBOutlet UILabel *sideDish1Label;
@property (weak, nonatomic) IBOutlet UILabel *sideDish2Label;
@property (weak, nonatomic) IBOutlet UILabel *sideDish3Label;
@property (weak, nonatomic) IBOutlet UILabel *sideDish4Label;

@property (weak, nonatomic) IBOutlet UIImageView *mainDishBannerImageView;
@property (weak, nonatomic) IBOutlet UIImageView *sideDish1BannerImageView;
@property (weak, nonatomic) IBOutlet UIImageView *sideDish2BannerImageView;
@property (weak, nonatomic) IBOutlet UIImageView *sideDish3BannerImageView;
@property (weak, nonatomic) IBOutlet UIImageView *sideDish4BannerImageView;

@property (weak, nonatomic) IBOutlet UIButton *addMainDishButton;
@property (weak, nonatomic) IBOutlet UIButton *addSideDish1Button;
@property (weak, nonatomic) IBOutlet UIButton *addSideDish2Button;
@property (weak, nonatomic) IBOutlet UIButton *addSideDish3Button;
@property (weak, nonatomic) IBOutlet UIButton *addSideDish4Button;

@property (weak, nonatomic) IBOutlet UIButton *buildButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buildButtonWidthConstraint;

@property (weak, nonatomic) IBOutlet UIButton *viewAddonsButton;

@property (nonatomic) id delegate;

@end
