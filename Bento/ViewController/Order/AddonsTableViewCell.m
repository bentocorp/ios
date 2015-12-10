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
#import "CAGradientLayer+SJSGradients.h"

@interface AddonsTableViewCell()

@property (nonatomic) UIView *maskView;
@property (nonatomic) CAGradientLayer *gradientLayer;
@property (nonatomic) NSMutableDictionary *dishInfo;

@end

@implementation AddonsTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        
        self.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
        
        self.dishInfo = [@{} mutableCopy];
        
        /*---Dish View---*/
        
        self.viewDish = [[UIView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2-((SCREEN_WIDTH-60)/2), 30, SCREEN_WIDTH-60, SCREEN_HEIGHT/2.5)];
        self.viewDish.layer.cornerRadius = 3;
        self.viewDish.clipsToBounds = YES;
        self.viewDish.backgroundColor = BORDER_COLOR;
        [self addSubview:self.viewDish];
        
        /*---Dish Image---*/
        
        self.ivAddon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.viewDish.frame.size.width, self.viewDish.frame.size.height - 45)];
        self.ivAddon.clipsToBounds = YES;
        self.ivAddon.contentMode = UIViewContentModeScaleAspectFill;
        [self.viewDish addSubview:self.ivAddon];
        
        /*---Gradient Layer---*/
        
        CAGradientLayer *backgroundLayer = [CAGradientLayer blackGradientLayer];
        backgroundLayer.frame = self.ivAddon.frame;
        backgroundLayer.opacity = 0.25f;
        [self.ivAddon.layer insertSublayer:backgroundLayer atIndex:0];
        
        /*---Dish Label---*/
        
        self.lblAddon = [[UILabel alloc] initWithFrame:CGRectMake(0, self.viewDish.frame.size.height - 45, self.viewDish.frame.size.width - 80, 45)];
        self.lblAddon.adjustsFontSizeToFitWidth = YES; // dynamically changes font size
        self.lblAddon.textColor = [UIColor bentoTitleGray];
        self.lblAddon.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        self.lblAddon.textAlignment = NSTextAlignmentCenter;
        self.lblAddon.backgroundColor = BORDER_COLOR;
        
        [self.viewDish addSubview:self.lblAddon];
        
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
        [self.maskView addSubview:self.descriptionLabel];
        
        /*---Dish Button---*/
        
        self.btnAddon = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.viewDish.frame.size.width, self.viewDish.frame.size.height)];
        [self.viewDish addSubview:self.btnAddon];
        
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
        
        self.ivBannerAddon = [[UIImageView alloc] initWithFrame:CGRectMake(self.viewDish.frame.size.width - self.viewDish.frame.size.height / 2, 0, self.self.viewDish.frame.size.height / 2, self.viewDish.frame.size.height / 2)];
        self.ivBannerAddon.image = soldOutBannerImage;
        [self.viewDish addSubview:self.ivBannerAddon];
        
        /*---Line Divider---*/
        
        UIView *lineDivider = [[UIView alloc] initWithFrame:CGRectMake(self.viewDish.frame.size.width - 80, self.viewDish.frame.size.height - 40, 1, self.lblAddon.frame.size.height-8)];
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
    }
    
    return self;
}

- (void)addDishInfo:(NSDictionary *)dishInfo
{
    self.dishInfo = [dishInfo mutableCopy];
    
    // NAME
    NSString *strName = [NSString stringWithFormat:@"%@", [self.dishInfo objectForKey:@"name"]];
    
    // DISH IMAGE
    NSString *strImageURL = [self.dishInfo objectForKey:@"image1"];
    if (strImageURL == nil || [strImageURL isEqualToString:@""]) {
        self.ivAddon.image = [UIImage imageNamed:@"empty-main"];
    }
    else {
        [self.ivAddon setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"gradient-placeholder2"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    }
    
    // DISH DESCRIPTION
    self.descriptionLabel.text = self.dishInfo[@"description"];
    
    // DISH LABEL
    self.lblAddon.text = [strName uppercaseString];
    
    // SOLD OUT
    NSInteger mainDishId = [[self.dishInfo objectForKey:@"itemId"] integerValue];
    if ([[BentoShop sharedInstance] isDishSoldOut:mainDishId]) {
        self.ivBannerAddon.hidden = NO;
        
        [self.subtractButton setImage:[UIImage imageNamed:@"minus-gray-100"] forState:UIControlStateNormal];
        self.subtractButton.enabled = NO;
        
        [self.addButton setImage:[UIImage imageNamed:@"plus-gray-100"] forState:UIControlStateNormal];
        self.addButton.enabled = NO;
        
        self.quantityLabel.textColor = [UIColor lightGrayColor];
    }
    else {
        self.ivBannerAddon.hidden = YES;
        
        [self.subtractButton setImage:[UIImage imageNamed:@"minus-green-100"] forState:UIControlStateNormal];
        self.subtractButton.enabled = YES;
        
        [self.addButton setImage:[UIImage imageNamed:@"plus-green-100"] forState:UIControlStateNormal];
        self.addButton.enabled = YES;
        
        self.quantityLabel.textColor = [UIColor bentoTitleGray];
    }
    
    // PRICE
    if ([self.dishInfo[@"price"] isEqual:[NSNull null]] || self.dishInfo[@"price"] == nil || self.dishInfo[@"price"] == 0 || [self.dishInfo[@"price"] isEqualToString:@""]) {
        
        // format to currency style
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
        self.priceLabel.text = [NSString stringWithFormat: @"%@", [numberFormatter stringFromNumber:@([[[BentoShop sharedInstance] getUnitPrice] floatValue])]]; // default settings.price
    }
    else {
        self.priceLabel.text = [NSString stringWithFormat: @"$%@", self.dishInfo[@"price"]]; // custom price
    }
}

- (void)setCellState:(BOOL)isSelected
{
    if (!isSelected) {
        self.descriptionLabel.hidden = YES;
        self.maskView.hidden = YES;
        
        // sold out
        NSInteger mainDishId = [[self.dishInfo objectForKey:@"itemId"] integerValue];
        if ([[BentoShop sharedInstance] isDishSoldOut:mainDishId]) {
            self.ivBannerAddon.hidden = NO;
        }
        else {
            self.ivBannerAddon.hidden = YES;
        }

    }
    else {
        self.descriptionLabel.hidden = NO;
        self.maskView.hidden = NO;
        self.ivBannerAddon.hidden = YES;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
