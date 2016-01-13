//
//  CustomViewController.h
//  Bento
//
//  Created by Joseph Lau on 1/8/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

@protocol CustomViewControllerDelegate <NSObject>

- (void)customVCAddMainButtonPressed:(id)sender;
- (void)customVCAddSideDish1Pressed:(id)sender;
- (void)customVCAddSideDish2Pressed:(id)sender;
- (void)customVCAddSideDish3Pressed:(id)sender;
- (void)customVCBottomButtonPressed:(id)sender;

@end

@interface CustomViewController : BaseViewController

@property (weak, nonatomic) IBOutlet UIView *dishBGView;

@property (weak, nonatomic) IBOutlet UIView *mainDishView;
@property (weak, nonatomic) IBOutlet UIView *sideDish1View;
@property (weak, nonatomic) IBOutlet UIView *sideDish2View;
@property (weak, nonatomic) IBOutlet UIView *sideDish3View;

@property (weak, nonatomic) IBOutlet UIImageView *mainDishImageView;
@property (weak, nonatomic) IBOutlet UIImageView *sideDish1ImageView;
@property (weak, nonatomic) IBOutlet UIImageView *sideDish2Imageview;
@property (weak, nonatomic) IBOutlet UIImageView *sideDish3ImageView;

@property (weak, nonatomic) IBOutlet UILabel *mainDishLabel;
@property (weak, nonatomic) IBOutlet UILabel *sideDish1Label;
@property (weak, nonatomic) IBOutlet UILabel *sideDish2Label;
@property (weak, nonatomic) IBOutlet UILabel *sideDish3Label;

@property (weak, nonatomic) IBOutlet UIButton *addMainButton;
@property (weak, nonatomic) IBOutlet UIButton *addSide1Button;
@property (weak, nonatomic) IBOutlet UIButton *addSide2Button;
@property (weak, nonatomic) IBOutlet UIButton *addSide3Button;

@property (weak, nonatomic) IBOutlet UIButton *buildButton;

@property (nonatomic) id delegate;

@end
