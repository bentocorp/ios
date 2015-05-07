//
//  SneakPreviewViewController.m
//  Bento
//
//  Created by RiSongIl on 2/24/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "SneakPreviewViewController.h"

#import "PreviewCollectionViewCell.h"

#import "FaqViewController.h"

#import "BentoShop.h"

@interface SneakPreviewViewController ()
{
    NSIndexPath *_selectedPath;
}

@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UICollectionView *cvDishes;

@end

@implementation SneakPreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Get current hour
    NSDate *currentDate = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitHour fromDate:currentDate];
    
    NSInteger hour = [components hour];
    NSLog(@"current hour - %ld", hour);
    
    // Sunday = 1, Saturday = 7
    int weekday = (int)[[calendar components:NSCalendarUnitWeekday fromDate:currentDate] weekday];
    NSLog(@"today is - %ld", (long)weekday);
    
    // if sold out || (closed && before 9pm && is not sunday && is not saturday)
    if ([[BentoShop sharedInstance] isSoldOut] ||
        (([[BentoShop sharedInstance] isClosed] && hour < 21) && weekday != 1 && weekday != 7)) {
        
        self.lblTitle.text = [NSString stringWithFormat:@"%@'s Menu", [[BentoShop sharedInstance] getMenuWeekdayString]];
        
    } else if ([[BentoShop sharedInstance] isClosed]) {
        
        self.lblTitle.text = [NSString stringWithFormat:@"%@'s Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
    }
    
    UINib *cellNib = [UINib nibWithNibName:@"PreviewCollectionViewCell" bundle:nil];
    [self.cvDishes registerNib:cellNib forCellWithReuseIdentifier:@"PreviewCollectionViewCell"];
    [self.cvDishes registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];

    _selectedPath = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"Faq"])
    {
        FaqViewController *vc = segue.destinationViewController;
        vc.contentType = [sender intValue];
    }
}

- (void)updateUI
{
    [self.cvDishes reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedMenu:) name:USER_NOTIFICATION_UPDATED_NEXTMENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
}

- (void)onUpdatedMenu:(NSNotification *)notification
{
    [self updateUI];
}

- (void)onUpdatedStatus:(NSNotification *)notification
{
    if (self.type == 0 && ![[BentoShop sharedInstance] isClosed]) // Closed
        [self performSelectorOnMainThread:@selector(doBack) withObject:nil waitUntilDone:NO];
    else if (self.type == 1 && ![[BentoShop sharedInstance] isSoldOut]) // Sold Out
        [self performSelectorOnMainThread:@selector(doBack) withObject:nil waitUntilDone:NO];
}

- (void)doBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onBack:(id)sender
{
    [self doBack];
}

- (IBAction)onFaq:(id)sender
{
    [self performSegueWithIdentifier:@"Faq" sender:[NSNumber numberWithInt:CONTENT_FAQ]];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (section == 0) // Main Dishes
    {
//        NSArray *aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes];
        
        NSArray *aryMainDishes;
        if ([[BentoShop sharedInstance] isSoldOut]) {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes];
        } else if ([[BentoShop sharedInstance] isClosed]) {
            aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes];
        }
        
        if (aryMainDishes == nil)
            return 0;
        
        return aryMainDishes.count;
    }
    else if (section == 1)
    {
//        NSArray *arySideDishes = [[BentoShop sharedInstance] getNextSideDishes];
        
        NSArray *arySideDishes;
        if ([[BentoShop sharedInstance] isSoldOut]) {
            arySideDishes = [[BentoShop sharedInstance] getSideDishes];
        } else if ([[BentoShop sharedInstance] isClosed]) {
            arySideDishes = [[BentoShop sharedInstance] getNextSideDishes];
        }

        if (arySideDishes == nil)
            return 0;
        
        return arySideDishes.count;
    }
    
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionViewCell *cell = (PreviewCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PreviewCollectionViewCell" forIndexPath:indexPath];
    
    [cell initView];
    
    if (indexPath.section == 1)
        [cell setSmallDishCell];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionViewCell *myCell = (PreviewCollectionViewCell *)cell;
    
//    myCell.layer.cornerRadius = 4;
//    myCell.layer.borderWidth = 1;
//    myCell.layer.borderColor = [[UIColor blackColor] CGColor];
    
    if (indexPath.section == 0) // Main Dish
    {
//        NSArray *aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes];
        NSArray *aryMainDishes;
        if ([[BentoShop sharedInstance] isSoldOut]) {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes];
            NSLog(@"Get today's menu");
        } else if ([[BentoShop sharedInstance] isClosed]) {
            aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes];
        }
        
        NSLog(@"Get today's menu - %@", [[BentoShop sharedInstance] getMainDishes]);
        NSLog(@"Get tomorrow's menu - %@", [[BentoShop sharedInstance] getNextMainDishes]);
        
        NSDictionary *dishInfo = [aryMainDishes objectAtIndex:indexPath.row];
        [myCell setDishInfo:dishInfo];
    }
    else if (indexPath.section == 1) // Side Dish
    {
//        NSArray *arySideDishes = [[BentoShop sharedInstance] getNextSideDishes];
        NSArray *arySideDishes;
        if ([[BentoShop sharedInstance] isSoldOut]) {
            arySideDishes = [[BentoShop sharedInstance] getSideDishes];
        } else if ([[BentoShop sharedInstance] isClosed]) {
            arySideDishes = [[BentoShop sharedInstance] getNextSideDishes];
        }
        
        NSDictionary *dishInfo = [arySideDishes objectAtIndex:indexPath.row];
        [myCell setDishInfo:dishInfo];
    }

    if (_selectedPath != nil && _selectedPath == indexPath)
    {
        [myCell setCellState:YES];
    }
    else
    {
        [myCell setCellState:NO];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) // Main Dish
    {
        return CGSizeMake(self.cvDishes.frame.size.width, self.cvDishes.frame.size.width * 3 / 5);
    }
    else if (indexPath.section == 1) // Side Dish
    {
        return CGSizeMake(self.cvDishes.frame.size.width / 2, self.cvDishes.frame.size.width / 2);
    }
    
    return CGSizeMake(0, 0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_selectedPath == indexPath)
    {
        _selectedPath = nil;
    }
    else
    {
        _selectedPath = indexPath;
    }
    
    [collectionView reloadData];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (section == 0 || section == 1)
    {
        return CGSizeMake(self.cvDishes.frame.size.width, 44);
    }
    
    return CGSizeMake(0, 0);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader])
    {
        UICollectionReusableView *reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        
        if (reusableview == nil)
            reusableview = [[UICollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, self.cvDishes.frame.size.width, 44)];

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
        
        reusableview.backgroundColor = [UIColor darkGrayColor];
        
        return reusableview;
    }
    
    return nil;
}

@end
