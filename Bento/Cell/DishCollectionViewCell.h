//
//  DishCollectionViewCell.h
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    DISH_CELL_NORMAL,
    DISH_CELL_FOCUS,
    DISH_CELL_SELECTED,
} DISH_CELL_STATE;

@protocol DishCollectionViewCellDelegate

- (void) onActionDishCell:(NSInteger)index;

@end

@interface DishCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) id <DishCollectionViewCellDelegate> delegate;

@property (nonatomic, weak) IBOutlet UIButton *btnAction;

- (void) setDishInfo:(NSDictionary *)dishInfo isSoldOut:(BOOL)isSoldOut canBeAdded:(BOOL)canBeAdded;

- (void) setSmallDishCell;
- (void) setCellState:(NSInteger)state index:(NSInteger)index;

@end
