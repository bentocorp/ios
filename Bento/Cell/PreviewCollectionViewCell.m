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

@property (nonatomic, weak) IBOutlet UIView *viewMain;

@property (nonatomic, weak) IBOutlet UIImageView *ivImage;

@property (nonatomic) CAGradientLayer *gradientLayer;

@property (nonatomic, weak) IBOutlet UILabel *lblTitle;
@property (nonatomic, weak) IBOutlet UILabel *lblDescription;

@property (nonatomic, weak) IBOutlet UIImageView *ivMask;

@end

@implementation PreviewCollectionViewCell

- (void)awakeFromNib
{
    _isSideDishCell = NO;
    
    self.ivMask.hidden = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
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
}

- (void)setSmallDishCell
{
    _isSideDishCell = YES;
}

- (void)setDishInfo:(NSDictionary *)dishInfo
{
    if (dishInfo == nil)
        return;
    
    NSString *strName = [dishInfo objectForKey:@"name"];
    self.lblTitle.text = [strName uppercaseString];
    
    NSString *strDescription = [dishInfo objectForKey:@"description"];
    self.lblDescription.text = strDescription;
    
    NSString *strImageURL = [dishInfo objectForKey:@"image1"];
    if (strImageURL == nil || [strImageURL isEqualToString:@""]) {
        self.ivImage.image = [UIImage imageNamed:@"empty-main"];
    }
    else {
        [self.ivImage sd_setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"empty-main"]];
    }
}

- (void)setCellState:(BOOL)isSelected
{
    if (!isSelected)
    {
        self.lblTitle.center = CGPointMake(self.lblTitle.center.x, self.viewMain.frame.size.height / 2);
        self.lblDescription.hidden = YES;
        self.ivMask.hidden = YES;
    }
    else
    {
        self.lblTitle.center = CGPointMake(self.lblTitle.center.x, 40);
        self.lblDescription.hidden = NO;
        self.ivMask.hidden = NO;
    }
}

@end
