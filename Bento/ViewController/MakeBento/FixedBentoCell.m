//
//  ServingLunchCell.m
//  Bento
//
//  Created by Joseph Lau on 5/5/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define BORDER_COLOR [UIColor colorWithRed:223.0f / 255.0f green:226.0f / 255.0f blue:226.0f / 255.0f alpha:1.0f]

#import "FixedBentoCell.h"
#import "CAGradientLayer+SJSGradients.h"
#import "UIImageView+WebCache.h"
#import <UIImageView+UIActivityIndicatorForSDWebImage.h>
#import "UIColor+CustomColors.h"

@implementation FixedBentoCell

- (void)awakeFromNib {
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        
        self.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
        
        /*---Dish View---*/
        
        self.viewDish = [[UIView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2-((SCREEN_WIDTH-60)/2), 30, SCREEN_WIDTH-60, SCREEN_HEIGHT/2.75)];
//        self.viewDish.backgroundColor = [UIColor colorWithRed:0.918f green:0.929f blue:0.929f alpha:1.0f];
        self.viewDish.layer.cornerRadius = 3;
        self.viewDish.clipsToBounds = YES;
        self.viewDish.layer.borderColor = BORDER_COLOR.CGColor;
        self.viewDish.layer.borderWidth = 1.0f;
        [self addSubview:self.viewDish];

        /*---Dish Image---*/
        
        self.ivMainDish = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.viewDish.frame.size.width, self.viewDish.frame.size.height - 45)];
        self.ivMainDish.clipsToBounds = YES;
        self.ivMainDish.contentMode = UIViewContentModeScaleAspectFill;
        [self.viewDish addSubview:self.ivMainDish];
        
        /*---Gradient Layer---*/
        
        CAGradientLayer *backgroundLayer = [CAGradientLayer blackGradientLayer];
        backgroundLayer.frame = self.ivMainDish.frame;
        backgroundLayer.opacity = 0.8f;
        [self.ivMainDish.layer insertSublayer:backgroundLayer atIndex:0];
        
        /*---Dish Label---*/
        
        self.lblMainDish = [[UILabel alloc] initWithFrame:CGRectMake(10, self.viewDish.frame.size.height - 45, self.viewDish.frame.size.width - 20, 45)];
        self.lblMainDish.adjustsFontSizeToFitWidth = YES; // dynamically changes font size
        self.lblMainDish.textColor = [UIColor bentoTitleGray];
        self.lblMainDish.font = [UIFont fontWithName:@"OpenSans-Bold" size:14.0f];
        self.lblMainDish.textAlignment = NSTextAlignmentCenter;
        [self.viewDish addSubview:self.lblMainDish];
        
        /*---Dish Button---*/
        
        self.btnMainDish = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.viewDish.frame.size.width, self.viewDish.frame.size.height)];
        [self.viewDish addSubview:self.btnMainDish];
        
        /*---Sold Out Banner---*/
        
        UIImage *soldOutBannerImage = [UIImage imageNamed:@"banner_sold_out"];
        
        self.ivBannerMainDish = [[UIImageView alloc] initWithFrame:CGRectMake(self.viewDish.frame.size.width - self.viewDish.frame.size.height / 2, 0, self.self.viewDish.frame.size.height / 2, self.viewDish.frame.size.height / 2)];
        self.ivBannerMainDish.image = soldOutBannerImage;
        [self.viewDish addSubview:self.ivBannerMainDish];
        
        /*---Add Button---*/
        self.addButton = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2-((SCREEN_WIDTH-60)/2), SCREEN_HEIGHT/3 + 55, SCREEN_WIDTH-60, 44)];
        self.addButton.layer.cornerRadius = 3;
        self.addButton.layer.masksToBounds = YES;
        self.addButton.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:14.0f];
        [self.addButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self addSubview:self.addButton];
        
        
        // Add Bento To Cart Label
        UILabel *addBentoToCartLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.addButton.frame.size.width * 0.75, self.addButton.frame.size.height)];
        addBentoToCartLabel.backgroundColor = [UIColor clearColor];
        addBentoToCartLabel.textColor = [UIColor whiteColor];
        addBentoToCartLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        addBentoToCartLabel.textAlignment = NSTextAlignmentCenter;
        addBentoToCartLabel.text = @"ADD BENTO TO CART";
        [self.addButton addSubview:addBentoToCartLabel];
        
        // Price Label
        self.priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.addButton.frame.size.width * 0.75, 0, self.addButton.frame.size.width - (self.addButton.frame.size.width * 0.75), self.addButton.frame.size.height)];
        self.priceLabel.backgroundColor = [UIColor clearColor];
        self.priceLabel.textColor = [UIColor whiteColor];
        self.priceLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        self.priceLabel.textAlignment = NSTextAlignmentCenter;
        [self.addButton addSubview:self.priceLabel];
        
        // Line divider
        UIView *lineDivider = [[UIView alloc] initWithFrame:CGRectMake(self.addButton.frame.size.width * 0.75, 4, 1, self.addButton.frame.size.height-8)];
        lineDivider.backgroundColor = [UIColor whiteColor];
        lineDivider.alpha = 0.1;
        [self.addButton addSubview:lineDivider];
    }
    
    return self;
}


- (void)setDishInfo:(NSDictionary *)dishInfo
{
    if (dishInfo == nil)
        return;
    
    NSString *strName = [NSString stringWithFormat:@"%@ Bento", [dishInfo objectForKey:@"name"]];
    self.lblMainDish.text = [strName uppercaseString];
    
    NSString *strImageURL = [dishInfo objectForKey:@"image1"];
    if (strImageURL == nil || [strImageURL isEqualToString:@""]) {
        self.ivMainDish.image = [UIImage imageNamed:@"empty-main"];
    }
    else {
//        [self.ivMainDish setImageWithURL:[NSURL URLWithString:strImageURL] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        
        [self.ivMainDish setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"gradient-placeholder2"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
