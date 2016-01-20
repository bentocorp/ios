//
//  MenuPreviewViewController.m
//  Bento
//
//  Created by Joseph Lau on 1/12/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#import "MenuPreviewViewController.h"
#import "PreviewCollectionViewCell.h"
#import "BentoShop.h"

@interface MenuPreviewViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@end

@implementation MenuPreviewViewController
{
    NSArray *aryMainDishes;
    NSArray *arySideDishes;
    NSArray *aryAddons;
    
    NSInteger _selectedPathMainRight;
    NSInteger _selectedPathSideRight;
    NSInteger _selectedPathAddonsRight;
    
    UICollectionView *cvDishes;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDictionary *widget = [[BentoShop sharedInstance] getOnDemandWidget];
    if (widget) {
        <#statements#>
    }
    
    /*---Collection View---*/
    
    // this sets the layout of the cells
    UICollectionViewFlowLayout *collectionViewFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    [collectionViewFlowLayout setMinimumLineSpacing:0];
    [collectionViewFlowLayout setMinimumInteritemSpacing:0];
    [cvDishes setCollectionViewLayout:collectionViewFlowLayout];
    
    cvDishes = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 94, SCREEN_WIDTH, SCREEN_HEIGHT - 94)
                                  collectionViewLayout:collectionViewFlowLayout];
    cvDishes.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
    cvDishes.dataSource = self;
    cvDishes.delegate = self;
    
    UINib *cellNib = [UINib nibWithNibName:@"PreviewCollectionViewCell" bundle:nil];
    [cvDishes registerNib:cellNib forCellWithReuseIdentifier:@"PreviewCollectionViewCell"];
    [cvDishes registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    [self.view addSubview:cvDishes];
    
    _selectedPathMainRight = -1;
    _selectedPathSideRight = -1;
    _selectedPathAddonsRight = -1;
}

#pragma mark - COLLECTION VIEW

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 3;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    [self setDishesBySection:section];
    
    // MAINS
    if (section == 0) {
        if (aryMainDishes == nil) {
            return 0;
        }
        
        return aryMainDishes.count;
    }
    // SIDES
    else if (section == 1) {
        if (arySideDishes == nil) {
            return 0;
        }
        
        return arySideDishes.count;
    }
    // ADD-ONS
    else if (section == 2) {
        if (aryAddons == nil) {
            return 0;
        }
        
        return aryAddons.count;
    }
    
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionViewCell *cell = (PreviewCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PreviewCollectionViewCell"
                                                                                                             forIndexPath:indexPath];
    [cell initView];
    
    // sides, set small
    if (indexPath.section == 1) {
        [cell setSmallDishCell];
    }
    
    /* Anything less than iOS 8.0 */
    if ([[UIDevice currentDevice].systemVersion intValue] < 8) {
        
        // MAINS
        if (indexPath.section == 0) {
            NSDictionary *dishInfo = [aryMainDishes objectAtIndex:indexPath.row];
            [cell setDishInfo:dishInfo];
            
            if (_selectedPathMainRight == indexPath.row) {
                [cell setCellState:YES];
            }
            else {
                [cell setCellState:NO];
            }
        }
        // SIDES
        else if (indexPath.section == 1) {
            NSDictionary *dishInfo = [arySideDishes objectAtIndex:indexPath.row];
            [cell setDishInfo:dishInfo];
            
            if (_selectedPathSideRight == indexPath.row) {
                [cell setCellState:YES];
            }
            else {
                [cell setCellState:NO];
            }
        }
        // ADD-ONS
        else {
            NSDictionary *dishInfo = [aryAddons objectAtIndex:indexPath.row];
            [cell setDishInfo:dishInfo];
            
            if (_selectedPathAddonsRight == indexPath.row) {
                [cell setCellState:YES];
            }
            else {
                [cell setCellState:NO];
            }
        }
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionViewCell *myCell = (PreviewCollectionViewCell *)cell;
    
    // MAINS
    if (indexPath.section == 0) {
        NSDictionary *dishInfo = [aryMainDishes objectAtIndex:indexPath.row];
        [myCell setDishInfo:dishInfo];
        
        if (_selectedPathMainRight == indexPath.row) {
            [myCell setCellState:YES];
        }
        else {
            [myCell setCellState:NO];
        }
    }
    // SIDES
    else if (indexPath.section == 1) {
        NSDictionary *dishInfo = [arySideDishes objectAtIndex:indexPath.row];
        [myCell setDishInfo:dishInfo];
        
        if (_selectedPathSideRight == indexPath.row) {
            [myCell setCellState:YES];
        }
        else {
            [myCell setCellState:NO];
        }
    }
    // ADD-ONS
    else {
        NSDictionary *dishInfo = [aryAddons objectAtIndex:indexPath.row];
        [myCell setDishInfo:dishInfo];
        
        if (_selectedPathAddonsRight == indexPath.row) {
            [myCell setCellState:YES];
        }
        else {
            [myCell setCellState:NO];
        }
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 || indexPath.section == 2) // Main Dish and Add-ons
        return CGSizeMake(cvDishes.frame.size.width, cvDishes.frame.size.width * 3 / 5);
    else if (indexPath.section == 1) // Side Dish
        return CGSizeMake(cvDishes.frame.size.width / 2, cvDishes.frame.size.width / 2);
    
    return CGSizeMake(0, 0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        if (_selectedPathMainRight == indexPath.row)
            _selectedPathMainRight = -1;
        else
        {
            _selectedPathMainRight = indexPath.row;
            _selectedPathSideRight = -1;
            _selectedPathAddonsRight = -1;
        }
    }
    else if (indexPath.section == 1)
    {
        if (_selectedPathSideRight == indexPath.row)
            _selectedPathSideRight = -1;
        else
        {
            _selectedPathSideRight = indexPath.row;
            _selectedPathMainRight = -1;
            _selectedPathAddonsRight = -1;
        }
    }
    else
    {
        if (_selectedPathAddonsRight == indexPath.row)
            _selectedPathAddonsRight = -1;
        else
        {
            _selectedPathAddonsRight = indexPath.row;
            _selectedPathMainRight = -1;
            _selectedPathSideRight = -1;
        }
    }
    
    [collectionView reloadData];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

// header
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(cvDishes.frame.size.width, 44);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader])
    {
        UICollectionReusableView *reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        
        if (reusableview == nil)
            reusableview = [[UICollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, cvDishes.frame.size.width, 44)];
        
        UILabel *label = (UILabel *)[reusableview viewWithTag:1];
        if (label == nil)
        {
            label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, reusableview.frame.size.width, reusableview.frame.size.height)];
            label.tag = 1;
            [reusableview addSubview:label];
        }
        
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont fontWithName:@"OpenSans-Semibold" size:16.0f];
        
        if (indexPath.section == 0)
            label.text = @"Main Dishes";
        else if (indexPath.section == 1)
            label.text = @"Side Dishes";
        else {
            label.text = @"Add-ons";
        }
        
        reusableview.backgroundColor = [UIColor darkGrayColor];
        
        return reusableview;
    }
    
    return nil;
}

#pragma mark Set Arrays

// No need to create method for today dishes array because we're only using todayDinner twice

- (void)setNextMainDishesArray:(NSString *)lunchOrDinner
{
    if ([lunchOrDinner isEqualToString:@"Lunch"])
        aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextLunchPreview"];
    
    else if ([lunchOrDinner isEqualToString:@"Dinner"])
        aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextDinnerPreview"];
}

- (void)setNextSideDishesArray:(NSString *)lunchOrDinner
{
    if ([lunchOrDinner isEqualToString:@"Lunch"])
        arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextLunchPreview"];
    
    else if ([lunchOrDinner isEqualToString:@"Dinner"])
        arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextDinnerPreview"];
}

- (void)setNextAddonsArray:(NSString *)lunchOrDinner
{
    if ([lunchOrDinner isEqualToString:@"Lunch"])
        aryAddons = [[BentoShop sharedInstance] getNextAddons:@"nextLunchPreview"];
    
    else if ([lunchOrDinner isEqualToString:@"Dinner"])
        aryAddons = [[BentoShop sharedInstance] getNextAddons:@"nextDinnerPreview"];
}

- (void)setDishesBySection:(NSInteger)section
{
    // MAIN DISHES
    if (section == 0)
    {
        /* IS ALL-DAY */
        if ([[BentoShop sharedInstance] isAllDay])
        {
            if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                [self setNextMainDishesArray:@"Lunch"];
            else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                [self setNextMainDishesArray:@"Dinner"];
        }
        
        /* IS NOT ALL-DAY */
        else
        {
            // 00:00 - 16:29
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
            {
                if ([[BentoShop sharedInstance] isThereDinnerMenu])
                    aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
                else if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    [self setNextMainDishesArray:@"Lunch"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    [self setNextMainDishesArray:@"Dinner"];
            }
            
            // 16:30 - 23:59
            else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    [self setNextMainDishesArray:@"Lunch"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    [self setNextMainDishesArray:@"Dinner"];
            }
        }
    }
    
    // SIDE DISHES
    else if (section == 1)
    {
        /* IS ALL-DAY */
        if ([[BentoShop sharedInstance] isAllDay])
        {
            if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                [self setNextSideDishesArray:@"Lunch"];
            else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                [self setNextSideDishesArray:@"Dinner"];
        }
        
        /* IS NOT ALL-DAY */
        else
        {
            // 00:00 - 16:29
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
            {
                if ([[BentoShop sharedInstance] isThereDinnerMenu])
                    arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
                else if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    [self setNextSideDishesArray:@"Lunch"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    [self setNextSideDishesArray:@"Dinner"];
            }
            
            // 16:30 - 23:59
            else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    [self setNextSideDishesArray:@"Lunch"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    [self setNextSideDishesArray:@"Dinner"];
            }
        }
    }
    
    // ADD-ONS
    else
    {
        /* IS ALL-DAY */
        if ([[BentoShop sharedInstance] isAllDay])
        {
            if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                [self setNextAddonsArray:@"Lunch"];
            else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                [self setNextAddonsArray:@"Dinner"];
        }
        
        /* IS NOT ALL-DAY */
        else
        {
            // 00:00 - 16:29
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
            {
                if ([[BentoShop sharedInstance] isThereDinnerMenu])
                    aryAddons = [[BentoShop sharedInstance] getAddons:@"todayDinner"];
                else if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    [self setNextAddonsArray:@"Lunch"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    [self setNextAddonsArray:@"Dinner"];
            }
            
            // 16:30 - 23:59
            else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    [self setNextAddonsArray:@"Lunch"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    [self setNextAddonsArray:@"Dinner"];
            }
        }
    }
}

@end
