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
#import <UIImageView+UIActivityIndicatorForSDWebImage.h>

#import "AppStrings.h"

#import "BentoShop.h"

#import "Mixpanel.h"

@interface DishCollectionViewCell()
{
    BOOL _isSoldOut;
    BOOL _canBeAdded;
    BOOL _isSideDishCell;
    
    BOOL trackingCurrentBento;
}

@property (nonatomic, weak) IBOutlet UIView *viewMain;

@property (nonatomic, weak) IBOutlet UIImageView *ivImage;
@property (nonatomic) CAGradientLayer *gradientLayer;

@property (nonatomic, weak) IBOutlet UILabel *lblTitle;
@property (nonatomic, weak) IBOutlet UILabel *lblDescription;

@property (nonatomic) BOOL hasSetOnce;
@property (nonatomic) BOOL isMain;
@property (nonatomic) NSString *strUnitPrice;

@property (nonatomic, weak) IBOutlet UIImageView *ivMask;

@property (nonatomic, weak) IBOutlet UIImageView *ivBanner;

@property (nonatomic) NSInteger state;
@property (nonatomic) NSInteger index;

@property (nonatomic) UIView *lineDivider;
@property (nonatomic) UILabel *addToBentoLabel;
@property (nonatomic) UILabel *unitPriceLabel;
@property (nonatomic) UILabel *priceTagLabel;


@end

@implementation DishCollectionViewCell

- (void)awakeFromNib
{
    _isSoldOut = NO;
    _canBeAdded = NO;
    _isSideDishCell = NO;
    
    CAGradientLayer *backgroundLayer = [CAGradientLayer blackGradientLayer];
    backgroundLayer.frame = self.ivImage.frame;
    [self.ivImage.layer insertSublayer:backgroundLayer atIndex:0];
    self.gradientLayer = backgroundLayer;
    self.gradientLayer.opacity = 0.8f;
    
    self.ivMask.hidden = YES;
}

- (IBAction)onAction:(id)sender
{
    if (_isSoldOut || (!_canBeAdded && self.state == DISH_CELL_FOCUS)) {
        return;
    }
    
    // if current bento is not empty
    if ([[[BentoShop sharedInstance] getCurrentBento] isEmpty]) {
        
        // if not tracked yet
        if (trackingCurrentBento == NO) {
            
            [[Mixpanel sharedInstance] track:@"Began Building A Bento"];
            
            trackingCurrentBento = YES;
            
            NSLog(@"BEGAN BUILDING A BENTO");
        }
    }
    else {
        // since current bento is already filled, it's been tracked already
        trackingCurrentBento = YES;
    }
    
    [self.delegate onActionDishCell:self.index];
}

// sets the title label of button
- (void)setSmallDishCell
{
    _isSideDishCell = YES;
    
    if (_isSoldOut) {
        [self.btnAction setTitle:@"Sold Out" forState:UIControlStateNormal];
    }
    else if (!_canBeAdded) {
        [self.btnAction setTitle:@"Reached to max" forState:UIControlStateNormal];
    }
    else {
        [self.btnAction setTitle:[[AppStrings sharedInstance] getString:SIDEDISH_ADD_BUTTON_NORMAL] forState:UIControlStateNormal];
    }
}

#pragma mark Cell Info
- (void)setDishInfo:(NSDictionary *)dishInfo isSoldOut:(BOOL)isSoldOut canBeAdded:(BOOL)canBeAdded isMain:(BOOL)isMain
{
    if (dishInfo == nil) {
        return;
    }
    
    _isSoldOut = isSoldOut;
    _canBeAdded = canBeAdded;
    
    // Name
    NSString *strName = dishInfo[@"name"];
    self.lblTitle.text = [strName uppercaseString];
    
    // Description
    NSString *strDescription = dishInfo[@"description"];
    self.lblDescription.text = strDescription;
    
    // Price by main
    if (isMain == YES) {
        if ([dishInfo[@"type"] isEqualToString:@"main"]) {
            self.isMain = isMain; // YES
            
            if ([dishInfo[@"price"] isEqual:[NSNull null]] || dishInfo[@"price"] == nil || dishInfo[@"price"] == 0 || [dishInfo[@"price"] isEqualToString:@""]) {
                self.strUnitPrice = @""; // null
            }
            else {
                self.strUnitPrice = dishInfo[@"price"]; // unit price
            }
        }
    }
    
    //
    if (self.isMain == YES && self.priceTagLabel == nil) {
        // price tag shown on normal state only
        self.priceTagLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width/2 - 30, self.frame.size.height - 46, 60, 36)];
        self.priceTagLabel.backgroundColor = [UIColor clearColor];
        self.priceTagLabel.textColor = [UIColor whiteColor];
        self.priceTagLabel.layer.cornerRadius = 5;
        self.priceTagLabel.layer.borderWidth = 1;
        self.priceTagLabel.layer.borderColor = [UIColor whiteColor].CGColor;
        self.priceTagLabel.textAlignment = NSTextAlignmentCenter;
        self.priceTagLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        [self addSubview:self.priceTagLabel];
    }
    
    // Image
    NSString *strImageURL = dishInfo[@"image1"];
    if (strImageURL == nil || [strImageURL isEqualToString:@""]) {
        self.ivImage.image = [UIImage imageNamed:@"empty-main"];
    }
    else {
        [self.ivImage setImageWithURL:[NSURL URLWithString:strImageURL]
                     placeholderImage:[UIImage imageNamed:@"gradient-placeholder2"]
          usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    }
}

#pragma mark Cell State
- (void)setCellState:(NSInteger)state index:(NSInteger)index
{
    self.viewMain.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    
    self.gradientLayer.frame = CGRectMake(0, 0, self.ivImage.frame.size.width, self.ivImage.frame.size.height);
    
    self.btnAction.layer.cornerRadius = 3;
    self.btnAction.clipsToBounds = YES;
    self.btnAction.layer.borderColor = [UIColor whiteColor].CGColor;
    self.btnAction.layer.borderWidth = 1.0f;
    
    // if current item is main
    if (self.isMain == YES) {
            
        // only create(set) the labels once! but OK to reset text!
        if (self.hasSetOnce == NO) {
            self.hasSetOnce = YES;
            
            // SPACING
            float priceSpacingWidth = (self.btnAction.frame.size.width - (self.btnAction.frame.size.width * 0.75));
            
            // ADD TO BENTO
            self.addToBentoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.btnAction.frame.size.width - priceSpacingWidth, self.btnAction.frame.size.height)];
            self.addToBentoLabel.textAlignment = NSTextAlignmentCenter;
            self.addToBentoLabel.backgroundColor = [UIColor clearColor];
            self.addToBentoLabel.font = [UIFont fontWithName:@"OpenSans-SemiBold" size:14];
            self.addToBentoLabel.text = [[AppStrings sharedInstance] getString: MAINDISH_ADD_BUTTON_NORMAL];
            [self.btnAction addSubview:self.addToBentoLabel];
            
            // PRICE LABEL
            self.unitPriceLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.btnAction.frame.size.width * 0.75, 0, priceSpacingWidth, self.btnAction.frame.size.height)];
            self.unitPriceLabel.textAlignment = NSTextAlignmentCenter;
            self.unitPriceLabel.backgroundColor = [UIColor clearColor];
            self.unitPriceLabel.font = [UIFont fontWithName:@"OpenSans-SemiBold" size:14];
            [self.btnAction addSubview:self.unitPriceLabel];
            
            // line divider
            self.lineDivider = [[UIView alloc] initWithFrame:CGRectMake(self.btnAction.frame.size.width * 0.75, 4, 1, self.btnAction.frame.size.height-8)];
            self.lineDivider.alpha = 0.2;
            [self.btnAction addSubview:self.lineDivider];
        }
        
        // check to see if price has been properly set
        if ([self.strUnitPrice isEqualToString:@""]) {
            // no price set
            
            // format to currency style
            NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
            [numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
            
            self.unitPriceLabel.text = [NSString stringWithFormat:@"%@", [numberFormatter stringFromNumber:@([[[BentoShop sharedInstance] getUnitPrice] floatValue])]]; // set default settings.price
        }
        else {
            self.unitPriceLabel.text = [NSString stringWithFormat:@"$%@", self.strUnitPrice]; // set unit price
        }

    }
    
    NSLog(@"priceLabel: %@", self.strUnitPrice);
    
    self.ivBanner.frame = CGRectMake(self.frame.size.width - self.frame.size.height / 2, 0, self.frame.size.height / 2, self.frame.size.height / 2);
    
    self.state = state;
    self.index = index;
    
    if (self.state == DISH_CELL_NORMAL) {
        
        self.lblTitle.center = CGPointMake(self.lblTitle.center.x, self.viewMain.frame.size.height / 2);
        self.lblDescription.hidden = YES;
        self.btnAction.hidden = YES;
        
        // price tag label for normal state only
        if (self.isMain == YES) {
            self.priceTagLabel.text = self.unitPriceLabel.text;
            self.priceTagLabel.hidden = NO;
        }
        
        // hide
        self.unitPriceLabel.hidden = YES;
        self.lineDivider.hidden = YES;
        self.addToBentoLabel.hidden = YES;
         
        self.ivMask.hidden = YES;
        
        if (_isSoldOut) {
            self.ivBanner.hidden = NO;
        }
        else {
            self.ivBanner.hidden = YES;
        }
    }
    else if (self.state == DISH_CELL_FOCUS) {
        
        self.lblTitle.center = CGPointMake(self.lblTitle.center.x, 40);
        
        self.btnAction.backgroundColor = [UIColor clearColor];
        [self.btnAction setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        // change to white color when button not yet tapped
        if (self.isMain == YES) {
            self.unitPriceLabel.textColor = [UIColor whiteColor];
            self.addToBentoLabel.textColor = [UIColor whiteColor];
            self.lineDivider.backgroundColor = [UIColor whiteColor];
            
            self.unitPriceLabel.hidden = NO;
            self.lineDivider.hidden = NO;
            self.addToBentoLabel.hidden = NO;
            
            self.addToBentoLabel.text = [[AppStrings sharedInstance] getString: MAINDISH_ADD_BUTTON_NORMAL];
            self.btnAction.userInteractionEnabled = YES;
            
            // price tag label for normal state only
            self.priceTagLabel.hidden = YES;
        }
        
        self.lblDescription.hidden = NO;
        self.btnAction.hidden = NO;
        self.ivBanner.hidden = YES;
        
        if (_isSoldOut) {
            if (self.isMain == YES) {
                self.addToBentoLabel.text = @"Sold Out";
                [self.btnAction setTitle:@"" forState:UIControlStateNormal];
            }
            else {
                [self.btnAction setTitle:@"Sold Out" forState:UIControlStateNormal];
            }
        }
        else if (!_canBeAdded) {
            if (self.isMain == YES) {
                self.addToBentoLabel.text = @"Reached to max";
                [self.btnAction setTitle:@"" forState:UIControlStateNormal];
            }
            else {
                [self.btnAction setTitle:@"Reached to max" forState:UIControlStateNormal];
            }
        }
        else {
            [UIView setAnimationsEnabled:NO];
            
            if (_isSideDishCell) {
                [self.btnAction setTitle:[[AppStrings sharedInstance] getString:SIDEDISH_ADD_BUTTON_NORMAL] forState:UIControlStateNormal];
            }
            // main
            else {
                [self.btnAction setTitle:@"" forState:UIControlStateNormal];
            }
            
            [UIView setAnimationsEnabled:YES];
        }
        
        self.ivMask.hidden = NO;
    }
    else if (self.state == DISH_CELL_SELECTED) {
        
        self.lblTitle.center = CGPointMake(self.lblTitle.center.x, 40);
        
        self.btnAction.backgroundColor = [UIColor whiteColor];
        [self.btnAction setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        // change to black color when button tapped
        if (self.isMain == YES) {
            self.unitPriceLabel.textColor = [UIColor blackColor];
            self.addToBentoLabel.textColor = [UIColor blackColor];
            self.lineDivider.backgroundColor = [UIColor blackColor];
            
            self.unitPriceLabel.hidden = NO;
            self.lineDivider.hidden = NO;
            self.addToBentoLabel.hidden = NO;
            
            // in your bento
            self.addToBentoLabel.text = [[AppStrings sharedInstance] getString:MAINDISH_ADD_BUTTON_SELECT];
            self.btnAction.userInteractionEnabled = YES;
            
            // price tag label for normal state only
            self.priceTagLabel.hidden = YES;
        }
        
        self.ivBanner.hidden = YES;
        self.lblDescription.hidden = NO;
        self.btnAction.hidden = NO;
        
        [UIView setAnimationsEnabled:NO];
        
        if (_isSideDishCell) {
            [self.btnAction setTitle:[[AppStrings sharedInstance] getString:SIDEDISH_ADD_BUTTON_SELECT] forState:UIControlStateNormal];
        }
        // main
        else {
            [self.btnAction setTitle:@"" forState:UIControlStateNormal];
        }
        
        [UIView setAnimationsEnabled:YES];
        
        self.ivMask.hidden = NO;
    }
}

@end
