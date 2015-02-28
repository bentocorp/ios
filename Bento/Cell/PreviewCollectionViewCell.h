//
//  PreviewCollectionViewCell.h
//  Bento
//
//  Created by RiSongIl on 2/24/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PreviewCollectionViewCell : UICollectionViewCell

- (void)initView;

- (void) setDishInfo:(NSDictionary *)dishInfo;
- (void) setSmallDishCell;
- (void) setCellState:(BOOL)isSelected;

@end
