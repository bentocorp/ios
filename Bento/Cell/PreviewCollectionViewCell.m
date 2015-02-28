//
//  PreviewCollectionViewCell.m
//  Bento
//
//  Created by RiSongIl on 2/24/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "PreviewCollectionViewCell.h"

#import "CAGradientLayer+SJSGradients.h"

#import "UIImageView+WebCache.h"

#import "AppStrings.h"

@interface PreviewCollectionViewCell()
{
    BOOL _isSideDishCell;
}

@property (nonatomic, assign) IBOutlet UIView *viewMain;

@property (nonatomic, assign) IBOutlet UIImageView *ivImage;

@property (nonatomic, assign) CAGradientLayer *gradientLayer;

@property (nonatomic, assign) IBOutlet UILabel *lblTitle;
@property (nonatomic, assign) IBOutlet UILabel *lblDescription;

@property (nonatomic, assign) IBOutlet UIImageView *ivMask;

//@property (nonatomic, assign) IBOutlet UIButton *btnAction;

@end

@implementation PreviewCollectionViewCell

- (void)awakeFromNib {
    // Initialization code
    _isSideDishCell = NO;
    
    self.ivMask.hidden = YES;
//    [self.btnAction setTitle:[[AppStrings sharedInstance] getString:SNEAK_PREVIEW_MAIN_DISH] forState:UIControlStateNormal];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    //self.gradientLayer.frame = self.ivImage.frame;
}

- (void)initView
{
    self.viewMain.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    
    if(self.gradientLayer != nil)
    {
        [self.gradientLayer removeFromSuperlayer];
        self.gradientLayer = nil;
    }
    
    self.gradientLayer = [CAGradientLayer blackGradientLayer];
    self.gradientLayer.opacity = 0.8f;
    self.gradientLayer.contentsGravity = @"resizeAspectFill";
    self.gradientLayer.frame = self.ivImage.frame;
    [self.ivImage.layer insertSublayer:self.gradientLayer atIndex:0];
    
    
//    self.btnAction.layer.cornerRadius = 3;
//    self.btnAction.clipsToBounds = YES;
//    self.btnAction.layer.borderColor = [UIColor whiteColor].CGColor;
//    self.btnAction.layer.borderWidth = 1.0f;
}

- (void) setSmallDishCell
{
    _isSideDishCell = YES;
    
//    [self.btnAction setTitle:[[AppStrings sharedInstance] getString:SNEAK_PREVIEW_SIDE_DISH] forState:UIControlStateNormal];
}

- (void) setDishInfo:(NSDictionary *)dishInfo
{
    if (dishInfo == nil)
        return;
    
    NSString *strName = [dishInfo objectForKey:@"name"];
    self.lblTitle.text = [strName uppercaseString];
    
    NSString *strDescription = [dishInfo objectForKey:@"description"];
    self.lblDescription.text = strDescription;
    
    NSString *strImageURL = [dishInfo objectForKey:@"image1"];
    [self.ivImage sd_setImageWithURL:[NSURL URLWithString:strImageURL]];
}

- (void) setCellState:(BOOL)isSelected
{
    if (!isSelected)
    {
        self.lblTitle.center = CGPointMake(self.lblTitle.center.x, self.viewMain.frame.size.height / 2);
        
        self.lblDescription.hidden = YES;
//        self.btnAction.hidden = YES;
        
        self.ivMask.hidden = YES;
    }
    else
    {
        self.lblTitle.center = CGPointMake(self.lblTitle.center.x, 40);
        
//        self.btnAction.backgroundColor = [UIColor clearColor];
//        [self.btnAction setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        self.lblDescription.hidden = NO;
        
//        self.btnAction.hidden = NO;
        
//        if (_isSideDishCell)
//            [self.btnAction setTitle:[[AppStrings sharedInstance] getString:SNEAK_PREVIEW_SIDE_DISH] forState:UIControlStateNormal];
//        else
//            [self.btnAction setTitle:[[AppStrings sharedInstance] getString:SNEAK_PREVIEW_MAIN_DISH] forState:UIControlStateNormal];

        self.ivMask.hidden = NO;
    }
}

@end
