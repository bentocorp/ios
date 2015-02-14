//
//  DishCollectionViewCell.m
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "DishCollectionViewCell.h"

#import "CAGradientLayer+SJSGradients.h"

#import "UIImageView+WebCache.h"

#import "AppStrings.h"

@interface DishCollectionViewCell()
{
    BOOL _isSoldOut;
    BOOL _canBeAdded;
    BOOL _isSideDishCell;
}

@property (nonatomic, assign) IBOutlet UIView *viewMain;

@property (nonatomic, assign) IBOutlet UIImageView *ivImage;
@property (nonatomic, assign) IBOutlet CAGradientLayer *gradientLayer;

@property (nonatomic, assign) IBOutlet UILabel *lblTitle;
@property (nonatomic, assign) IBOutlet UILabel *lblDescription;



@property (nonatomic, assign) IBOutlet UIImageView *ivMask;

@property (nonatomic, assign) IBOutlet UIImageView *ivBanner;

@property (nonatomic, assign) NSInteger state;
@property (nonatomic, assign) NSInteger index;

@end

@implementation DishCollectionViewCell

- (void)awakeFromNib {
    // Initialization code
    _isSoldOut = NO;
    _canBeAdded = NO;
    _isSideDishCell = NO;
    
    CAGradientLayer *backgroundLayer = [CAGradientLayer blackGradientLayer];
    backgroundLayer.frame = self.ivImage.frame;
    [self.ivImage.layer insertSublayer:backgroundLayer atIndex:0];
    self.gradientLayer = backgroundLayer;
    self.gradientLayer.opacity = 0.96f;
    
    self.ivMask.hidden = YES;
    [self.btnAction setTitle:[[AppStrings sharedInstance] getString:MAINDISH_ADD_BUTTON_NORMAL] forState:UIControlStateNormal];
}

- (IBAction)onAction:(id)sender
{
    if (_isSoldOut || (!_canBeAdded && self.state == DISH_CELL_FOCUS))
        return;
    
    [self.delegate onActionDishCell:self.index];
}

- (void) setSmallDishCell
{
    _isSideDishCell = YES;
    
    self.lblTitle.font = [UIFont fontWithName:self.lblTitle.font.fontName size:14];
    self.lblDescription.font = [UIFont fontWithName:self.lblDescription.font.fontName size:14];
    
    if (_isSoldOut)
        [self.btnAction setTitle:@"Sold Out" forState:UIControlStateNormal];
    else if (!_canBeAdded)
        [self.btnAction setTitle:@"Reached to max" forState:UIControlStateNormal];
    else
        [self.btnAction setTitle:[[AppStrings sharedInstance] getString:SIDEDISH_ADD_BUTTON_NORMAL] forState:UIControlStateNormal];
}

- (void) setDishInfo:(NSDictionary *)dishInfo isSoldOut:(BOOL)isSoldOut canBeAdded:(BOOL)canBeAdded
{
    if (dishInfo == nil)
        return;
    
    _isSoldOut = isSoldOut;
    _canBeAdded = canBeAdded;
    
    NSString *strName = [dishInfo objectForKey:@"name"];
    self.lblTitle.text = [strName uppercaseString];
    
    NSString *strDescription = [dishInfo objectForKey:@"description"];
    self.lblDescription.text = strDescription;
    
    NSString *strImageURL = [dishInfo objectForKey:@"image1"];
    [self.ivImage sd_setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"sample"]];
}

- (void) setCellState:(NSInteger)state index:(NSInteger)index
{
    self.viewMain.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    
    self.gradientLayer.frame = CGRectMake(0, 0, self.ivImage.frame.size.width, self.ivImage.frame.size.height);
    
    self.btnAction.layer.cornerRadius = 3;
    self.btnAction.clipsToBounds = YES;
    self.btnAction.layer.borderColor = [UIColor whiteColor].CGColor;
    self.btnAction.layer.borderWidth = 1.0f;
    
    self.ivBanner.frame = CGRectMake(self.frame.size.width - self.frame.size.height / 2, 0, self.frame.size.height / 2, self.frame.size.height / 2);
    
    self.state = state;
    self.index = index;
    
    if (self.state == DISH_CELL_NORMAL)
    {
        self.lblTitle.center = CGPointMake(self.lblTitle.center.x, self.viewMain.frame.size.height / 2);
        
        self.lblDescription.hidden = YES;
        self.btnAction.hidden = YES;
        
        self.ivMask.hidden = YES;
        
        if (_isSoldOut)
            self.ivBanner.hidden = NO;
        else
            self.ivBanner.hidden = YES;
    }
    else if (self.state == DISH_CELL_FOCUS)
    {
        self.lblTitle.center = CGPointMake(self.lblTitle.center.x, 40);
        self.lblDescription.center = CGPointMake(self.lblDescription.center.x, self.viewMain.frame.size.height / 2);
        self.btnAction.center = CGPointMake(self.btnAction.center.x, self.viewMain.frame.size.height - 40);
        
        self.btnAction.backgroundColor = [UIColor clearColor];
        [self.btnAction setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        self.lblDescription.hidden = NO;
        
        self.btnAction.hidden = NO;
        
        self.ivBanner.hidden = YES;
        
        if (_isSoldOut)
        {
            [self.btnAction setTitle:@"Sold Out" forState:UIControlStateNormal];
        }
        else if (!_canBeAdded)
        {
            [self.btnAction setTitle:@"Reached to max" forState:UIControlStateNormal];
        }
        else
        {
            [UIView setAnimationsEnabled:NO];
            
            if (_isSideDishCell)
                [self.btnAction setTitle:[[AppStrings sharedInstance] getString:SIDEDISH_ADD_BUTTON_NORMAL] forState:UIControlStateNormal];
            else
                [self.btnAction setTitle:[[AppStrings sharedInstance] getString:MAINDISH_ADD_BUTTON_NORMAL] forState:UIControlStateNormal];
            
            [UIView setAnimationsEnabled:YES];
        }
        
        self.ivMask.hidden = NO;
    }
    else if (self.state == DISH_CELL_SELECTED)
    {
        self.lblTitle.center = CGPointMake(self.lblTitle.center.x, 40);
        self.lblDescription.center = CGPointMake(self.lblDescription.center.x, self.viewMain.frame.size.height / 2);
        self.btnAction.center = CGPointMake(self.btnAction.center.x, self.viewMain.frame.size.height - 40);
        
        self.btnAction.backgroundColor = [UIColor whiteColor];
        [self.btnAction setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        self.ivBanner.hidden = YES;
        
        self.lblDescription.hidden = NO;
        
        self.btnAction.hidden = NO;
        
        [UIView setAnimationsEnabled:NO];
        
        if (_isSideDishCell)
            [self.btnAction setTitle:[[AppStrings sharedInstance] getString:SIDEDISH_ADD_BUTTON_SELECT] forState:UIControlStateNormal];
        else
            [self.btnAction setTitle:[[AppStrings sharedInstance] getString:MAINDISH_ADD_BUTTON_SELECT] forState:UIControlStateNormal];
        
        [UIView setAnimationsEnabled:YES];
        
        self.ivMask.hidden = NO;
    }
}

@end
