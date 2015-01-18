//
//  DishCollectionViewCell.m
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "DishCollectionViewCell.h"

#import "CAGradientLayer+SJSGradients.h"

@interface DishCollectionViewCell()

@property (nonatomic, assign) IBOutlet UIView *viewMain;

@property (nonatomic, assign) IBOutlet UIImageView *ivImage;
@property (nonatomic, assign) IBOutlet CAGradientLayer *gradientLayer;

@property (nonatomic, assign) IBOutlet UILabel *lblTitle;
@property (nonatomic, assign) IBOutlet UILabel *lblDescription;

@property (nonatomic, assign) IBOutlet UIButton *btnAction;

@property (nonatomic, assign) IBOutlet UIImageView *ivMask;

@property (nonatomic, assign) NSInteger state;
@property (nonatomic, assign) NSInteger index;

@end

@implementation DishCollectionViewCell

- (void)awakeFromNib {
    // Initialization code
    
    CAGradientLayer *backgroundLayer = [CAGradientLayer blackGradientLayer];
    backgroundLayer.frame = self.ivImage.frame;
    [self.ivImage.layer insertSublayer:backgroundLayer atIndex:0];
    self.gradientLayer = backgroundLayer;
    self.gradientLayer.opacity = 0.96f;
    
    self.ivMask.hidden = YES;
}

- (IBAction)onAction:(id)sender
{
    [self.delegate onActionDishCell:self.index];
}

- (void) setSmallDishCell
{
    self.lblTitle.font = [UIFont fontWithName:self.lblTitle.font.fontName size:14];
    self.lblDescription.font = [UIFont fontWithName:self.lblDescription.font.fontName size:14];
}

- (void) setCellState:(NSInteger)state index:(NSInteger)index
{
    self.viewMain.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    
    self.gradientLayer.frame = CGRectMake(0, 0, self.ivImage.frame.size.width, self.ivImage.frame.size.height);
    
    self.btnAction.layer.cornerRadius = 3;
    self.btnAction.clipsToBounds = YES;
    self.btnAction.layer.borderColor = [UIColor whiteColor].CGColor;
    self.btnAction.layer.borderWidth = 1.0f;
    
    self.state = state;
    self.index = index;
    
    if(self.state == DISH_CELL_NORMAL)
    {
        self.lblTitle.center = CGPointMake(self.lblTitle.center.x, self.viewMain.frame.size.height / 2);
        
        self.lblDescription.hidden = YES;
        self.btnAction.hidden = YES;
        
        self.ivMask.hidden = YES;
    }
    else if(self.state == DISH_CELL_FOCUS)
    {
        self.lblTitle.center = CGPointMake(self.lblTitle.center.x, 40);
        self.lblDescription.center = CGPointMake(self.lblDescription.center.x, self.viewMain.frame.size.height / 2);
        self.btnAction.center = CGPointMake(self.btnAction.center.x, self.viewMain.frame.size.height - 40);
        
        self.btnAction.backgroundColor = [UIColor clearColor];
        [self.btnAction setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        self.lblDescription.hidden = NO;
        self.btnAction.hidden = NO;
        
        self.ivMask.hidden = NO;
    }
    else if(self.state == DISH_CELL_SELECTED)
    {
        self.lblTitle.center = CGPointMake(self.lblTitle.center.x, 40);
        self.lblDescription.center = CGPointMake(self.lblDescription.center.x, self.viewMain.frame.size.height / 2);
        self.btnAction.center = CGPointMake(self.btnAction.center.x, self.viewMain.frame.size.height - 40);
        
        self.btnAction.backgroundColor = [UIColor whiteColor];
        [self.btnAction setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        self.lblDescription.hidden = NO;
        self.btnAction.hidden = NO;
        
        self.ivMask.hidden = NO;
    }
}

@end
