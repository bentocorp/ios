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

@property (nonatomic) NSMutableArray *aryBentos;
@property (nonatomic) BOOL _isPaused;
@property (nonatomic) CGFloat iosMinVersion;
@property (nonatomic) CGFloat iosCurrentVersion;

+ (BentoShop *)sharedInstance;
+ (void)releaseInstance;


- (BOOL)isAllDay;
- (BOOL)nextIsAllDay;

- (BOOL)isClosed;
- (BOOL)isSoldOut;

- (void)setSignInStatus:(BOOL)status;
- (BOOL)isSignedIn;

- (BOOL)canAddDish:(NSInteger)dishID;
- (BOOL)isDishSoldOut:(NSInteger)menuID;

- (void)getStatus;
- (void)setStatus:(NSArray *)menuStatus;
- (void)getMenus;
- (void)getNextMenus;
- (void)getServiceArea;

- (void)setBranchParams:(NSDictionary *)params;
- (NSDictionary *)getBranchParams;

- (NSURL *)getMenuImageURL;
- (NSString *)getMenuDateString;
- (NSString *)getMenuWeekdayString;
- (NSString *)getNextMenuDateIfTodayMenuReturnsNil;

- (NSString *)getNextMenuDateString;
- (NSString *)getNextMenuWeekdayString;

- (BOOL)isThereLunchMenu;
- (BOOL)isThereDinnerMenu;
- (BOOL)isThereLunchNextMenu;
- (BOOL)isThereDinnerNextMenu;

typedef void (^GetInit2Block)(BOOL succeeded, NSError *error);
- (void)getInit2:(GetInit2Block)completion;

//typedef void (^GetInit2GateKeeperBlock)(BOOL succeeded, NSError *error);
- (void)getInit2WithGateKeeper;

- (void)getiOSMinAndCurrentVersions;
- (void)getCurrentLunchDinnerBufferTimesInNumbersAndVersionNumbers;
- (NSNumber *)getCurrentTime;
- (NSNumber *)getLunchTime;
- (NSNumber *)getDinnerTime;
- (NSNumber *)getBufferTime;
- (NSString *)getLunchMapURL;
- (NSString *)getDinnerMapURL;
- (NSString *)getGeofenceRadius;

- (NSInteger)getETAMin;
- (NSInteger)getETAMax;

- (void)refreshStart;
- (void)refreshPause;
- (void)refreshResume;
- (void)refreshStop;

- (NSArray *)getMainDishes:(NSString *)whatNeedsMain;
- (NSArray *)getSideDishes:(NSString *)whatNeedsSides;
- (NSArray *)getAddons:(NSString *)whatNeedsAddons;

- (NSArray *)getNextMainDishes:(NSString *)whatNeedsMain;
- (NSArray *)getNextSideDishes:(NSString *)whatNeedsSides;
- (NSArray *)getNextAddons:(NSString *)whatNeedsAddons;

- (NSDictionary *)getMainDish:(NSInteger)mainDishID;
- (NSDictionary *)getSideDish:(NSInteger)sideDishID;

- (MKPolygon *)getPolygon;
//- (BOOL)checkLocation:(CLLocationCoordinate2D)location;
- (BOOL)isInAnyZone;

typedef void (^SelectedLocationCheckBlock)(BOOL isSelectedLocationInZone, NSString *appState);
- (void)checkIfSelectedLocationIsInAnyZone:(CLLocationCoordinate2D)coordinate completion:(SelectedLocationCheckBlock)completion;

typedef void (^SendRequestCompletionBlock)(id responseDic, NSError *error);
- (void)sendRequest:(NSString *)strRequest completion:(SendRequestCompletionBlock)completion;

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

//- (void)checkIfBentoArrayNeedsToBeReset;

- (NSString *)getUnitPrice;
- (NSString *)getSalePrice;
- (float)getDeliveryPrice;
- (NSString *)getTaxPercent;

- (BOOL)is4PodMode;

- (NSString *)getAppState;
- (NSDictionary *)getOnDemandWidget;
- (BOOL)isThereWidget;
- (BOOL)isThereOnDemand;
- (BOOL)isThereOrderAhead;
- (BOOL)isThereOnDemandPreview;
- (NSArray *)getOrderAheadMenus;
- (NSString *)setDateFormat:(NSString *)dateString;
- (NSString *)convert24To12HoursWithoutAMPM:(NSString *)time;
- (NSString *)convert24To12HoursWithAMPM:(NSString *)time;

- (NSString *)getLunchCutOffTime;
- (NSString *)getDinnerCutOffTime;
- (NSString *)getCountDownMinutes;

- (NSString *)getKitchen;
- (NSString *)getOAZone;

@end
