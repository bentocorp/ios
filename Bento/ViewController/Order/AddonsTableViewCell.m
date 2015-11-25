//
//  AddonsTableViewCell.m
//  Bento
//
//  Created by Joseph Lau on 11/17/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define BORDER_COLOR [UIColor colorWithRed:223.0f / 255.0f green:226.0f / 255.0f blue:226.0f / 255.0f alpha:1.0f]

#import "AddonsTableViewCell.h"
#import "UIImageView+WebCache.h"
#import <UIImageView+UIActivityIndicatorForSDWebImage.h>
#import "UIColor+CustomColors.h"
#import "BentoShop.h"

@interface AddonsTableViewCell()

@property (nonatomic) UIView *maskView;
@property (nonatomic) CAGradientLayer *gradientLayer;
@property (nonatomic) NSDictionary *dishInfo;

@end

@implementation AddonsTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier dishInfo:(NSDictionary *)dishInfo
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        
        self.dishInfo = dishInfo;
        
        self.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
        
        /*---Dish View---*/
        
        self.viewDish = [[UIView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2-((SCREEN_WIDTH-60)/2), 30, SCREEN_WIDTH-60, SCREEN_HEIGHT/2.5)];
        self.viewDish.layer.cornerRadius = 3;
        self.viewDish.clipsToBounds = YES;
        self.viewDish.backgroundColor = BORDER_COLOR;
        [self addSubview:self.viewDish];
        
        /*---Dish Image---*/
        
        self.ivMainDish = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.viewDish.frame.size.width, self.viewDish.frame.size.height - 45)];
        self.ivMainDish.clipsToBounds = YES;
        self.ivMainDish.contentMode = UIViewContentModeScaleAspectFill;
        [self.viewDish addSubview:self.ivMainDish];
        
        // NAME
        NSString *strName = [NSString stringWithFormat:@"%@", [dishInfo objectForKey:@"name"]];
        
        NSString *strImageURL = [dishInfo objectForKey:@"image1"];
        if (strImageURL == nil || [strImageURL isEqualToString:@""]) {
            self.ivMainDish.image = [UIImage imageNamed:@"empty-main"];
        }
        else {
            [self.ivMainDish setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"gradient-placeholder2"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        }
        
        /*---Dish Label---*/
        
        self.lblMainDish = [[UILabel alloc] initWithFrame:CGRectMake(0, self.viewDish.frame.size.height - 45, self.viewDish.frame.size.width - 80, 45)];
        self.lblMainDish.adjustsFontSizeToFitWidth = YES; // dynamically changes font size
        self.lblMainDish.textColor = [UIColor bentoTitleGray];
        self.lblMainDish.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        self.lblMainDish.textAlignment = NSTextAlignmentCenter;
        self.lblMainDish.backgroundColor = BORDER_COLOR;
        self.lblMainDish.text = [strName uppercaseString];
        [self.viewDish addSubview:self.lblMainDish];
        
        /*---Mask View---*/
        
        self.maskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.viewDish.frame.size.width, self.viewDish.frame.size.height - 45)];
        self.maskView.backgroundColor = [UIColor blackColor];
        self.maskView.alpha = 0.7;
        [self.viewDish addSubview:self.maskView];
        
        /*---Description Label---*/
        
        self.descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, self.maskView.frame.size.height / 2 - 50, self.maskView.frame.size.width - 10, 100)];
        self.descriptionLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        self.descriptionLabel.textColor = [UIColor whiteColor];
        self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
        self.descriptionLabel.adjustsFontSizeToFitWidth = YES;
        self.descriptionLabel.numberOfLines = 0;
        self.descriptionLabel.text = dishInfo[@"description"];
        [self.maskView addSubview:self.descriptionLabel];
        
        /*---Dish Button---*/
        
        self.btnMainDish = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.viewDish.frame.size.width, self.viewDish.frame.size.height)];
        [self.viewDish addSubview:self.btnMainDish];
        
        /*---Subtract Button---*/
        
        self.subtractButton = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH * .25 - 25, self.viewDish.frame.size.height + 45, 50, 50)];
        [self addSubview:self.subtractButton];
        
        /*---Add Button---*/
        
        self.addButton = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH * .75 - 25, self.viewDish.frame.size.height + 45, 50, 50)];
        [self addSubview:self.addButton];
        
        /*---Quantity Label---*/
        
        self.quantityLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2 - 50, self.viewDish.frame.size.height + 45, 100, 50)];
        self.quantityLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:30];
        self.quantityLabel.textColor = [UIColor bentoTitleGray];
        self.quantityLabel.textAlignment = NSTextAlignmentCenter;
        self.quantityLabel.text = [NSString stringWithFormat:@"%i", 0];
        [self addSubview:self.quantityLabel];
        
        /*---Sold Out Banner---*/
        
        UIImage *soldOutBannerImage = [UIImage imageNamed:@"banner_sold_out"];
        
        self.ivBannerMainDish = [[UIImageView alloc] initWithFrame:CGRectMake(self.viewDish.frame.size.width - self.viewDish.frame.size.height / 2, 0, self.self.viewDish.frame.size.height / 2, self.viewDish.frame.size.height / 2)];
        self.ivBannerMainDish.image = soldOutBannerImage;
        [self.viewDish addSubview:self.ivBannerMainDish];
        
        NSInteger mainDishId = [[dishInfo objectForKey:@"itemId"] integerValue];
        if ([[BentoShop sharedInstance] isDishSoldOut:mainDishId]) {
            self.ivBannerMainDish.hidden = NO;
            
            [self.subtractButton setImage:[UIImage imageNamed:@"minus-gray-100"] forState:UIControlStateNormal];
            self.subtractButton.enabled = NO;
            
            [self.addButton setImage:[UIImage imageNamed:@"plus-gray-100"] forState:UIControlStateNormal];
            self.addButton.enabled = NO;
        }
        else {
            self.ivBannerMainDish.hidden = YES;
            
            [self.subtractButton setImage:[UIImage imageNamed:@"minus-green-100"] forState:UIControlStateNormal];
            self.subtractButton.enabled = YES;
            
            [self.addButton setImage:[UIImage imageNamed:@"plus-green-100"] forState:UIControlStateNormal];
            self.addButton.enabled = YES;
        }
        
        /*---Line Divider---*/
        
        UIView *lineDivider = [[UIView alloc] initWithFrame:CGRectMake(self.viewDish.frame.size.width - 80, self.viewDish.frame.size.height - 40, 1, self.lblMainDish.frame.size.height-8)];
        lineDivider.backgroundColor = [UIColor bentoButtonGray];
        lineDivider.alpha = 0.2;
        [self.viewDish addSubview:lineDivider];
        
        /*---Price Label---*/
        
        self.priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.viewDish.frame.size.width - 80, self.viewDish.frame.size.height - 45, 80, 45)];
        self.priceLabel.backgroundColor = [UIColor clearColor];
        self.priceLabel.textColor = [UIColor bentoTitleGray];
        self.priceLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        self.priceLabel.textAlignment = NSTextAlignmentCenter;
        [self.viewDish addSubview:self.priceLabel];
        
        if ([dishInfo[@"price"] isEqual:[NSNull null]] || dishInfo[@"price"] == nil || dishInfo[@"price"] == 0 || [dishInfo[@"price"] isEqualToString:@""]) {
            
            // format to currency style
            NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
            [numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
            self.priceLabel.text = [NSString stringWithFormat: @"%@", [numberFormatter stringFromNumber:@([[[BentoShop sharedInstance] getUnitPrice] floatValue])]]; // default settings.price
        }
        else {
            self.priceLabel.text = [NSString stringWithFormat: @"$%@", dishInfo[@"price"]]; // custom price
        }
    }
    
    return self;
}

- (void)setCellState:(BOOL)isSelected
{
    if (!isSelected) {
        self.descriptionLabel.hidden = YES;
        self.maskView.hidden = YES;
        
        // sold out
        NSInteger mainDishId = [[self.dishInfo objectForKey:@"itemId"] integerValue];
        if ([[BentoShop sharedInstance] isDishSoldOut:mainDishId]) {
            self.ivBannerMainDish.hidden = NO;
        }
        else {
            self.ivBannerMainDish.hidden = YES;
        }

    }
    else {
        self.descriptionLabel.hidden = NO;
        self.maskView.hidden = NO;
        self.ivBannerMainDish.hidden = YES;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
