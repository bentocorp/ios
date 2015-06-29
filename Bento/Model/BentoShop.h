//
//  BentoShop.h
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Bento.h"

#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface BentoShop : NSObject
{
//    BOOL _isPaused;
    BOOL _isCallingApi;
    
    NSTimer *_timer;
    NSInteger _currentIndex;
}

#define USER_NOTIFICATION_UPDATED_MENU      @"user_notification_updated_menu"
#define USER_NOTIFICATION_UPDATED_STATUS    @"user_notification_updated_status"
#define USER_NOTIFICATION_UPDATED_AREA      @"user_notification_updated_area"
#define USER_NOTIFICATION_UPDATED_NEXTMENU  @"user_notification_updated_nextmenu"

@property (nonatomic) BOOL _isPaused;
@property (nonatomic) CGFloat iosMinVersion;
@property (nonatomic) CGFloat iosCurrentVersion;

+ (BentoShop *)sharedInstance;
+ (void)releaseInstance;

- (BOOL)isAllDay;
- (BOOL)nextIsAllDay;
- (BOOL)nextNextIsAllDay;

- (BOOL)isClosed;
- (BOOL)isSoldOut;

- (BOOL)canAddDish:(NSInteger)dishID;
- (BOOL)isDishSoldOut:(NSInteger)menuID;

- (void)getStatus;
- (void)setStatus:(NSArray *)menuStatus;
- (void)getMenus;
- (void)getServiceArea;

- (NSURL *)getMenuImageURL;
- (NSString *)getMenuDateString;
- (NSString *)getMenuWeekdayString;
- (NSString *)getNextMenuDateIfTodayMenuReturnsNil;

- (NSString *)getNextMenuDateString;
- (NSString *)getNextMenuWeekdayString;
- (NSString *)getNextNextMenuWeekdayString;

- (BOOL)isThereLunchMenu;
- (BOOL)isThereDinnerMenu;
- (BOOL)isThereLunchNextMenu;
- (BOOL)isThereDinnerNextMenu;
- (BOOL)isThereLunchNextNextMenu;
- (BOOL)isThereDinnerNextNextMenu;

- (void)getCurrentLunchDinnerBufferTimesInNumbersAndVersionNumbers;
- (NSNumber *)getCurrentTime;
- (NSNumber *)getLunchTime;
- (NSNumber *)getDinnerTime;
- (NSNumber *)getBufferTime;
- (NSString *)getLunchMapURL;
- (NSString*)getDinnerMapURL;

- (void)refreshStart;
- (void)refreshPause;
- (void)refreshResume;
- (void)refreshStop;

- (NSString *)getMenuType;

- (NSArray *)getMainDishes:(NSString *)whatNeedsMain;
- (NSArray *)getSideDishes:(NSString *)whatNeedsSides;

- (NSArray *)getNextMainDishes:(NSString *)whatNeedsMain;
- (NSArray *)getNextSideDishes:(NSString *)whatNeedsSides;

- (NSArray *)getNextNextMainDishes:(NSString *)whatNeedsMain;
- (NSArray *)getNextNextSideDishes:(NSString *)whatNeedsSides;

- (NSDictionary *)getMainDish:(NSInteger)mainDishID;
- (NSDictionary *)getSideDish:(NSInteger)sideDishID;

- (MKPolygon *)getPolygon;
- (BOOL)checkLocation:(CLLocationCoordinate2D)location;

- (NSInteger)getTotalBentoCount;
- (NSInteger)getCompletedBentoCount;

- (Bento *)getCurrentBento;
- (void)setCurrentBento:(Bento *)bento;
- (Bento *)getBento:(NSInteger)bentoIndex;
- (Bento *)getLastBento;

- (void)addNewBento;
- (void)removeBento:(Bento *)bento;

- (void)loadBentoArray;
- (void)saveBentoArray;
- (void)resetBentoArray;

- (void)checkIfBentoArrayNeedsToBeReset;
- (void)setLunchOrDinnerModeByTimes;

- (BOOL)didModeOrDateChange;

@end
