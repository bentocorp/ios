//
//  BaseViewController.h
//  Bento
//
//  Created by RiSongIl on 2/4/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseViewController : UIViewController

@property (nonatomic, assign) BOOL isOpenningAccountView;

@property (nonatomic, assign) Class nextViewController;

@property (nonatomic, strong) void (^complete)();

- (void) openAccountViewController:(id) nextViewControllerClass;
- (void) openAccountViewControllerWithComplete:(void (^)())completion;

- (void) showSoldoutScreen:(NSNumber *)identifier;

@end
