//
//  PreviewViewController.m
//  Bento
//
//  Created by Joseph Lau on 5/7/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "PreviewViewController.h"
#import "BWTitlePagerView.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface PreviewViewController ()

@end

@implementation PreviewViewController
{
    UIScrollView *scrollView;
    
    UILabel *lblTitle;
    UICollectionView *cvDishes;
    
    NSIndexPath *_selectedPath;
    
    NSInteger hour;
    int weekday;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /*---Scroll View---*/
    
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 45, SCREEN_WIDTH, SCREEN_HEIGHT)];
    scrollView.contentSize = CGSizeMake(SCREEN_WIDTH*2, SCREEN_HEIGHT-65);
    scrollView.pagingEnabled = YES;
    scrollView.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
    scrollView.bounces = NO;
    [self.view addSubview:scrollView];
    
    /*---Navigation View---*/
    
    UIView *navigationBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 65)];
    navigationBarView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navigationBarView];
    
    /*---BW Title Pager View---*/
    
    BWTitlePagerView *pagingTitleView = [[BWTitlePagerView alloc] init];
    pagingTitleView.frame = CGRectMake(SCREEN_WIDTH/2-100, 32.5 - 10, 200, 40);
    pagingTitleView.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    pagingTitleView.currentTintColor = [UIColor colorWithRed:0.341f green:0.376f blue:0.439f alpha:1.0f];
    [pagingTitleView observeScrollView:scrollView];
    [pagingTitleView addObjects:@[@"Today's Lunch", @"Tonight's Dinner"]]; // make dynamic
    [navigationBarView addSubview:pagingTitleView];
    
    /*---Line Separator---*/
    
    UIView *longLineSepartor1 = [[UIView alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, 1)];
    longLineSepartor1.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
    [navigationBarView addSubview:longLineSepartor1];
    
    /*---Back button---*/
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 50, 45)];
    [closeButton setImage:[UIImage imageNamed:@"nav_btn_back"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(onCloseButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    /*---Collection View---*/
    
    // this sets the layout of the cells
    UICollectionViewFlowLayout *collectionViewFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    [collectionViewFlowLayout setMinimumLineSpacing:0];
    [collectionViewFlowLayout setMinimumInteritemSpacing:0];
    [cvDishes setCollectionViewLayout:collectionViewFlowLayout];
    
    cvDishes = [[UICollectionView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH, 0, SCREEN_WIDTH, SCREEN_HEIGHT-65) collectionViewLayout:collectionViewFlowLayout];
    cvDishes.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
    cvDishes.dataSource = self;
    cvDishes.delegate = self;
    
    UINib *cellNib = [UINib nibWithNibName:@"PreviewCollectionViewCell" bundle:nil];
    [cvDishes registerNib:cellNib forCellWithReuseIdentifier:@"PreviewCollectionViewCell"];
    [cvDishes registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    
    [scrollView addSubview:cvDishes];
    
    // Get current hour
    NSDate *currentDate = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitHour fromDate:currentDate];
    
    hour = [components hour];
    NSLog(@"current hour - %ld", hour);
    
    // Sunday = 1, Saturday = 7
    weekday = (int)[[calendar components:NSCalendarUnitWeekday fromDate:currentDate] weekday];
    NSLog(@"today is - %ld", (long)weekday);
    
    // set menu title
    //    // if sold out || (closed && before 9pm && is not sunday && is not saturday)
    //    if ([[BentoShop sharedInstance] isSoldOut] ||
    //        (([[BentoShop sharedInstance] isClosed] && hour < 21) && weekday != 1 && weekday != 7)) {
    //
    //        self.lblTitle.text = [NSString stringWithFormat:@"%@'s Menu", [[BentoShop sharedInstance] getMenuWeekdayString]];
    //
    //    } else if ([[BentoShop sharedInstance] isClosed]) {
    //
    //        self.lblTitle.text = [NSString stringWithFormat:@"%@'s Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
    //    }
    
    _selectedPath = nil;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)onCloseButton
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
