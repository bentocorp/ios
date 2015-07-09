//
//  BaseViewController.h
//  Bento
//
//  Created by RiSongIl on 2/4/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseViewController : UIViewController

@property (nonatomic) BOOL isOpenningAccountView;

@property (nonatomic) Class nextViewController;

@property (nonatomic) void (^complete)();

- (void) openAccountViewController:(id) nextViewControllerClass;
- (void) openAccountViewControllerWithComplete:(void (^)())completion;

- (void) showSoldoutScreen:(NSNumber *)identifier;

@end
