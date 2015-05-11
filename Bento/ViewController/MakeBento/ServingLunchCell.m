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

#import "ServingLunchCell.h"
#import "CAGradientLayer+SJSGradients.h"

@implementation ServingLunchCell
{
    UIView *viewDish;
}

- (void)awakeFromNib {
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        
        self.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
        
        /*---Dish View---*/
        
        viewDish = [[UIView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2-((SCREEN_WIDTH-60)/2), 20, SCREEN_WIDTH-60, SCREEN_HEIGHT/3 + 4)];
        viewDish.backgroundColor = [UIColor colorWithRed:0.918f green:0.929f blue:0.929f alpha:1.0f];
        viewDish.layer.cornerRadius = 3;
        viewDish.clipsToBounds = YES;
        viewDish.layer.borderColor = BORDER_COLOR.CGColor;
        viewDish.layer.borderWidth = 1.0f;
        [self addSubview:viewDish];

        /*---Dish Image---*/
        
        self.ivMainDish = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, viewDish.frame.size.width, viewDish.frame.size.height - 65)];
        self.ivMainDish.clipsToBounds = YES;
        self.ivMainDish.contentMode = UIViewContentModeScaleAspectFill;
        [viewDish addSubview:self.ivMainDish];
        
        /*---Gradient Layer---*/
        
        CAGradientLayer *backgroundLayer = [CAGradientLayer blackGradientLayer];
        backgroundLayer.frame = self.ivMainDish.frame;
        backgroundLayer.opacity = 0.8f;
        [self.ivMainDish.layer insertSublayer:backgroundLayer atIndex:0];
        
        /*---Dish Label---*/
        
        self.lblMainDish = [[UILabel alloc] initWithFrame:CGRectMake(0, viewDish.frame.size.height - 65, viewDish.frame.size.width + 2, 65)];
        self.lblMainDish.textColor = [UIColor colorWithRed:0.341f green:0.376f blue:0.439f alpha:1.0f];
        self.lblMainDish.font = [UIFont fontWithName:@"OpenSans-Bold" size:18.0f];
        self.lblMainDish.textAlignment = NSTextAlignmentCenter;
        [viewDish addSubview:self.lblMainDish];
        
        /*---Dish Button---*/
        
        self.btnMainDish = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, viewDish.frame.size.width, viewDish.frame.size.height)];
        [viewDish addSubview:self.btnMainDish];
        
        /*---Sold Out Banner---*/
        
        UIImage *soldOutBannerImage = [UIImage imageNamed:@"banner_sold_out"];
        
        self.ivBannerMainDish = [[UIImageView alloc] initWithFrame:CGRectMake(viewDish.frame.size.width - viewDish.frame.size.height / 2, 0, viewDish.frame.size.height / 2, viewDish.frame.size.height / 2)];
        self.ivBannerMainDish.image = soldOutBannerImage;
        [viewDish addSubview:self.ivBannerMainDish];
        
        /*---Add Button---*/
        UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2-((SCREEN_WIDTH-60)/2), SCREEN_HEIGHT/3 + 30, SCREEN_WIDTH-60, 44)];
        addButton.layer.cornerRadius = 3;
        addButton.layer.masksToBounds = YES;
        addButton.backgroundColor = [UIColor colorWithRed:0.918f green:0.929f blue:0.929f alpha:1.0f];
        addButton.titleLabel.text = @"Add To Cart";
        addButton.titleLabel.textColor = [UIColor whiteColor];
        [self addSubview:addButton];
        
        /*---Line Separator---*/
        
        UIView *longLineSepartor1 = [[UIView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 2 - 50, SCREEN_HEIGHT/3 + 100, 100, 1)];
        longLineSepartor1.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
        [self addSubview:longLineSepartor1];
    }
    
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
