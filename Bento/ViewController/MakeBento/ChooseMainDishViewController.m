//
//  ChooseMainDishViewController.m
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "ChooseMainDishViewController.h"

#import "DishCollectionViewCell.h"

@interface ChooseMainDishViewController ()<DishCollectionViewCellDelegate>
{
    NSInteger _selectedIndex;
    NSInteger _selectedItemState;
}

@property (nonatomic, assign) IBOutlet UICollectionView *cvMainDishes;

@property (nonatomic, assign) IBOutlet UILabel *lblBadge;

@property (nonatomic, assign) IBOutlet UIButton *btnCart;

@end

@implementation ChooseMainDishViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.lblBadge.layer.cornerRadius = self.lblBadge.frame.size.width / 2;
    self.lblBadge.clipsToBounds = YES;
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSInteger mainDishIndex = [[prefs objectForKey:@"MainDish"] integerValue];
    
    if(mainDishIndex == -1)
    {
        _selectedIndex = NSNotFound;
        _selectedItemState = DISH_CELL_NORMAL;
    }
    else
    {
        _selectedIndex = mainDishIndex;
        _selectedItemState = DISH_CELL_SELECTED;
    }
    
    UINib *cellNib = [UINib nibWithNibName:@"DishCollectionViewCell" bundle:nil];
    [self.cvMainDishes registerNib:cellNib forCellWithReuseIdentifier:@"cell"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.cvMainDishes reloadData];
    
    [self updateUI];
}

- (IBAction)onBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onCart:(id)sender
{
    
}

- (void) updateUI
{
    
    self.btnCart.selected = [self isCompletedToMakeMyBento];
}

- (BOOL) isCompletedToMakeMyBento
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSInteger mainDishIndex = [[prefs objectForKey:@"MainDish"] integerValue];
    
    if(mainDishIndex == -1)
    {
        return NO;
    }
    
    NSInteger sideDishIndex = [[prefs objectForKey:@"SideDish1"] integerValue];
    
    if(sideDishIndex == -1)
    {
        return NO;
    }
    
    sideDishIndex = [[prefs objectForKey:@"SideDish2"] integerValue];
    
    if(sideDishIndex == -1)
    {
        return NO;
    }
    
    sideDishIndex = [[prefs objectForKey:@"SideDish3"] integerValue];
    
    if(sideDishIndex == -1)
    {
        return NO;
    }
    
    sideDishIndex = [[prefs objectForKey:@"SideDish4"] integerValue];
    
    if(sideDishIndex == -1)
    {
        return NO;
    }
    
    return YES;
}

#pragma mark - UICollectionViewDatasource Methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return 10;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    DishCollectionViewCell *cell = (DishCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.delegate = self;
    
    if(_selectedIndex == indexPath.item)
    {
        [cell setCellState:_selectedItemState index:indexPath.item];
    }
    else
    {
        [cell setCellState:DISH_CELL_NORMAL index:indexPath.item];
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.cvMainDishes.frame.size.width, self.cvMainDishes.frame.size.width / 2);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if(_selectedIndex == indexPath.item)
    {

    }
    else
    {
        _selectedIndex = indexPath.item;
        _selectedItemState = DISH_CELL_FOCUS;
    }
    
    [collectionView reloadData];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark DishCollectionViewCellDelegate

- (void) onActionDishCell:(NSInteger)index
{
    _selectedIndex = index;
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    if(_selectedItemState == DISH_CELL_SELECTED)
    {
        _selectedItemState = DISH_CELL_FOCUS;
        
        [prefs setValue:[NSNumber numberWithInteger:-1] forKey:@"MainDish"];
    }
    else
    {
        _selectedItemState = DISH_CELL_SELECTED;
        
        [prefs setValue:[NSNumber numberWithInteger:_selectedIndex] forKey:@"MainDish"];
    }
    
    [prefs synchronize];
    
    [self.cvMainDishes reloadData];
    
    [self updateUI];
}



@end
