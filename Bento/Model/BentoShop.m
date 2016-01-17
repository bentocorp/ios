//
//  BentoShop.m
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "BentoShop.h"
#import "Bento.h"

#import "DataManager.h"
#import "AppStrings.h"

#import "SDWebImagePrefetcher.h"
#import "NSUserDefaults+RMSaveCustomObject.h"

#import "FirstViewController.h"

#import "Reachability.h"
#import <SystemConfiguration/SystemConfiguration.h>

#import "Mixpanel.h"
#import "Mixpanel/MPTweakInline.h"

#import "AddonList.h"

#import <AFNetworking/AFNetworking.h>

@interface BentoShop ()
 
@property (nonatomic) NSDictionary *dicInit2;
@property (nonatomic) NSDictionary *dictInit2WithGateKeeper;
@property (nonatomic) NSDictionary *dicStatus;
@property (nonatomic) NSDictionary *menuToday;
@property (nonatomic) NSDictionary *menuNext;
@property (nonatomic) NSArray *menuStatus;
@property (nonatomic) MKPolygon *serviceArea;
@property (nonatomic) NSMutableArray *aryBentos;
@property (nonatomic) NSString *strToday;
@property (nonatomic) BOOL prevClosed;
@property (nonatomic) BOOL prevSoldOut;

@end

@implementation BentoShop
{
    NSUserDefaults *defaults;
    
    NSString *originalStatus;
    NSString *currentMode;
    NSString *todayDate; // ?
    NSString *dinnerMapURLString;
    NSString *lunchMapURLString;
    NSString *geofenceOrderRadiusMetersString;
    
    NSDictionary *branchParams;
    
    float lunchTime;
    float dinnerTime;
    float currentTime;
    float bufferTime;
    
    BOOL signedIn;
}

static BentoShop *_shareInstance;

+ (BentoShop *)sharedInstance {
    @synchronized(self) {
        if (_shareInstance == nil) {
            _shareInstance = [[BentoShop alloc] init];
        }
    }
    
    return _shareInstance;
}

+ (void)releaseInstance {
    if (_shareInstance != nil)
        _shareInstance = nil;
}

- (id)init {
    if ( (self = [super init]) ) {
        defaults = [NSUserDefaults standardUserDefaults];
        
        self.prevClosed = NO;
        self.prevSoldOut = NO;
        
        self.strToday = nil;
        self.dicStatus = nil;
        self.menuToday = nil;
        self.menuNext = nil;
        self.menuStatus = nil;
        self.serviceArea = nil;
        
        self._isPaused = NO;
        _isCallingApi = NO;
        _currentIndex = NSNotFound;
        
        [self loadBentoArray];
        
        if (self.aryBentos == nil) {
            self.aryBentos = [[NSMutableArray alloc] init];
        }
    }
    
    // set original status to empty string when app launches the first time!!
    originalStatus = @"";
    
    return self;
}

typedef void (^SendRequestCompletionBlock)(id responseDic);

- (void)sendRequest:(NSString *)strRequest completion:(SendRequestCompletionBlock)completion {
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", SERVER_URL, strRequest]];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        }
        else {
            completion(responseObject);
        }
    }];
    
    [dataTask resume];
}

- (void)getInit2 {
    [self sendRequest:@"/init2" completion:^(id responseDic) {
        self.dicInit2 = (NSDictionary *)responseDic;
    }];
}

- (void)getInit2WithGateKeeper {
    // date, lat, lng
    [self sendRequest:@"/init2?date=%@&copy=1&gatekeeper=1&lat=%@&long=%@" completion:^(id responseDic) {
        self.dictInit2WithGateKeeper = (NSDictionary *)responseDic;
    }];
}

- (void)getStatus {
    self.dicStatus = self.dicInit2[@"/status/all"];
    self.menuStatus = self.dicInit2[@"/status/menu"];
    
    if (originalStatus.length == 0) {
        originalStatus = self.dicStatus[@"overall"][@"value"];
    }
    
    NSString *newStatus = self.dicStatus[@"overall"][@"value"];
    
    if (![originalStatus isEqualToString:newStatus])
    {
        [[AppStrings sharedInstance] getAppStrings];
        
        originalStatus = @"";
        
        NSLog(@"STATUS CHANGED!!! GET APP STRINGS!!!");
    }
    
    BOOL isClosed = [self isClosed];
    BOOL isSoldOut = [self isSoldOut];
    
    [self getNextMenus];

    [[NSNotificationCenter defaultCenter] postNotificationName:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    
    self.prevClosed = isClosed;
    self.prevSoldOut = isSoldOut;
}

- (void)setStatus:(NSArray *)menuStatus
{
    if (menuStatus == nil)
        return;
    
    self.menuStatus = [menuStatus copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:USER_NOTIFICATION_UPDATED_STATUS object:nil];
}

- (NSString *)getDateString
{
    NSDate* currentDate = [NSDate date];
    
#ifdef DEBUG
    NSTimeZone* currentTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT-08:00"];
    NSTimeZone* nowTimeZone = [NSTimeZone systemTimeZone];
    
    NSInteger currentGMTOffset = [currentTimeZone secondsFromGMTForDate:currentDate];
    NSInteger nowGMTOffset = [nowTimeZone secondsFromGMTForDate:currentDate];
    
    NSTimeInterval interval = currentGMTOffset - nowGMTOffset;
    currentDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:currentDate];
#endif
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd"];
    
    NSString *strDate = [formatter stringFromDate:currentDate];
    currentDate = nil;
    formatter = nil;
    
    return strDate;
}

#pragma mark Branch Params

- (void)setBranchParams:(NSDictionary *)params
{
    branchParams = params;
    
    NSLog(@"SET BRANCH PARAMS: %@", params);
}

- (NSDictionary *)getBranchParams
{
    NSLog(@"GET BRANCH PRAMS: %@", branchParams);
    
    return branchParams;
}

#pragma mark Get Menus

- (void)prefetchImages:(NSDictionary *)menuInfo
{
    if (menuInfo == nil)
        return;
    
    // instantiate empty array to hold urls
    NSMutableArray *urls = [[NSMutableArray alloc] init];
    
    // add bg images from lunch and dinner
    if (menuInfo != nil)
    {
        for (NSDictionary *menuDetailedInfo in menuInfo)
        {
            NSString *strMenuBack = menuInfo[menuDetailedInfo][@"Menu"][@"bgimg"]; // ie. menuInfo[@"lunch"][@"Menu"][@"bgimg"]

            if (strMenuBack != nil && [strMenuBack isKindOfClass:[NSString class]] && strMenuBack.length > 0)
                [urls addObject:[NSURL URLWithString:strMenuBack]];

        }
    }
    
    // add lunch images
    NSMutableArray *aryDishesLunch = menuInfo[@"lunch"][@"MenuItems"];
    if (aryDishesLunch != nil && [aryDishesLunch isKindOfClass:[NSArray class]] && aryDishesLunch.count > 0)
    {
        for (NSDictionary *dishInfo in aryDishesLunch)
        {
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            
            if (strImageURL != nil && [strImageURL isKindOfClass:[NSString class]] && strImageURL.length > 0)
                [urls addObject:[NSURL URLWithString:strImageURL]];
        }
    }
    
    // add dinner images
    NSMutableArray *aryDishesDinner = menuInfo[@"dinner"][@"MenuItems"];
    if (aryDishesDinner != nil && [aryDishesDinner isKindOfClass:[NSArray class]] && aryDishesDinner.count > 0)
    {
        for (NSDictionary *dishInfo in aryDishesDinner)
        {
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];

            if (strImageURL != nil && [strImageURL isKindOfClass:[NSString class]] && strImageURL.length > 0)
                [urls addObject:[NSURL URLWithString:strImageURL]];
        }
    }

    if (urls.count > 0)
        [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:urls];
}

- (void)getMenus
{
    NSString *strDate = [self getDateString];
    
    NSString *strRequest = [NSString stringWithFormat:@"%@/menu/%@", SERVER_URL, strDate];
    
    NSError *error = nil;
    self.menuToday = [self sendRequest:strRequest statusCode:nil error:&error][@"menus"];
    
    // set menuInfo and menuItems to persistent storage
    [defaults setObject:self.menuToday[@"lunch"][@"Menu"] forKey:@"lunchMenuInfo"];
    [defaults setObject:self.menuToday[@"dinner"][@"Menu"] forKey:@"dinnerMenuInfo"];
    
    NSData *dataLunch = [NSKeyedArchiver archivedDataWithRootObject:self.menuToday[@"lunch"][@"MenuItems"]];
    NSData *dataDinner = [NSKeyedArchiver archivedDataWithRootObject:self.menuToday[@"dinner"][@"MenuItems"]];
    [defaults setObject:dataLunch forKey:@"lunchMenuItems"];
    [defaults setObject:dataDinner forKey:@"dinnerMenuItems"];
    [defaults synchronize];
    
    [self prefetchImages:self.menuToday];
    
    // if today date is not same as date from backend
    if (![strDate isEqualToString:self.strToday])
    {
        [self resetBentoArray];

        self.strToday = strDate;
        [[NSNotificationCenter defaultCenter] postNotificationName:USER_NOTIFICATION_UPDATED_MENU object:nil];
    }
    
    NSLog(@"Menu - %@", self.menuToday[@"lunch"][@"MenuItems"]);
}

- (void)getNextMenus
{
    NSDate* currentDate = [NSDate date];
    
#ifdef DEBUG
    NSTimeZone* currentTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT-08:00"];
    NSTimeZone* nowTimeZone = [NSTimeZone systemTimeZone];
    
    NSInteger currentGMTOffset = [currentTimeZone secondsFromGMTForDate:currentDate];
    NSInteger nowGMTOffset = [nowTimeZone secondsFromGMTForDate:currentDate];
    
    NSTimeInterval interval = currentGMTOffset - nowGMTOffset;
    currentDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:currentDate];
#endif
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd"];
    NSString *strDate = [formatter stringFromDate:currentDate];
    
    NSString *strRequest = [NSString stringWithFormat:@"%@/menu/next/%@", SERVER_URL, strDate];
    
    NSError *error = nil;
    NSInteger statusCode = 0;
    self.menuNext = [self sendRequest:strRequest statusCode:&statusCode error:&error][@"menus"];

    // set menuInfo and menuItems to persistent storage
    [defaults setObject:self.menuNext[@"lunch"][@"Menu"] forKey:@"nextLunchMenuInfo"];
    [defaults setObject:self.menuNext[@"dinner"][@"Menu"] forKey:@"nextDinnerMenuInfo"];
    
    /* archive array before setting into defaults - because there may be null values for unset inventory count */
    NSData *dataNextLunch = [NSKeyedArchiver archivedDataWithRootObject:self.menuNext[@"lunch"][@"MenuItems"]];
    NSData *dataNextDinner = [NSKeyedArchiver archivedDataWithRootObject:self.menuNext[@"dinner"][@"MenuItems"]];
    [defaults setObject:dataNextLunch forKey:@"nextLunchMenuItems"];
    [defaults setObject:dataNextDinner forKey:@"nextDinnerMenuItems"];
    
    [defaults synchronize];
    
    [self prefetchImages:self.menuNext];
    [[NSNotificationCenter defaultCenter] postNotificationName:USER_NOTIFICATION_UPDATED_NEXTMENU object:nil];
}

- (NSString *)getNextMenuDateIfTodayMenuReturnsNil
{
    // there is a menu today! return today string!
    if ([self getMenuDateString] != nil)
        return [self getMenuWeekdayString];
    // bummer... no menu today.. return next date string
    else
        return [self getNextMenuWeekdayString];
}

#pragma mark Times, Version Numbers, iOS Min Version

- (void)getCurrentLunchDinnerBufferTimesInNumbersAndVersionNumbers
{
    // Get time strings from /init call
    NSString *lunchTimeString = self.dicInit[@"meals"][@"2"][@"startTime"];
    NSString *dinnerTimeString = self.dicInit[@"meals"][@"3"][@"startTime"];
    
    // set date format
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"k:mm:ss"];
    
    // format dates from strings
    NSDate *dateLunch = [formatter dateFromString:lunchTimeString];
    NSDate *dateDinner = [formatter dateFromString:dinnerTimeString];
    
    // convert to date components
    NSDateComponents * componentsLunch = [[NSCalendar currentCalendar] components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:dateLunch];
    NSDateComponents * componentsDinner = [[NSCalendar currentCalendar] components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:dateDinner];
    
    // Lunch and Dinner
    lunchTime = (float)[componentsLunch hour] + ((float)[componentsLunch minute] / 60);
    dinnerTime = (float)[componentsDinner hour] + ((float)[componentsDinner minute] / 60);
    
    // Buffer Time
    NSString *bufferString = self.dicInit[@"settings"][@"buffer_minutes"];
    bufferTime = [bufferString floatValue] / 60;
    
    // Current Time
    NSDateComponents *componentsCurrent = [[NSCalendar currentCalendar] components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:[NSDate date]];
    currentTime = (float)[componentsCurrent hour] + ((float)[componentsCurrent minute] / 60);
}

- (NSInteger)getETAMin
{
    if (self.dicInit[@"eta"] != nil && ![self.dicInit isEqual:[NSNull null]]) {
        return [self.dicInit[@"eta"][@"eta_min"] integerValue];
    }
    
    return 0;
}

- (NSInteger)getETAMax
{
    if (self.dicInit[@"eta"] != nil && ![self.dicInit isEqual:[NSNull null]]) {
        return [self.dicInit[@"eta"][@"eta_max"] integerValue];
    }
    
    return 0;
}

- (void)getiOSMinAndCurrentVersions {
    /*------------------for forced update---------------*/
    self.iosMinVersion = (CGFloat)[self.dicInit[@"settings"][@"ios_min_version"] floatValue];
    self.iosCurrentVersion = (CGFloat)[[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] floatValue];
}

- (NSNumber *)getCurrentTime
{
    NSLog(@"Get Current Time - %@", [NSNumber numberWithFloat:currentTime]);
    return [NSNumber numberWithFloat:currentTime];
}

- (NSNumber *)getLunchTime
{
    NSLog(@"Get Lunch Time - %@", [NSNumber numberWithFloat:lunchTime]);
    return [NSNumber numberWithFloat:lunchTime];
}

- (NSNumber *)getDinnerTime
{
    NSLog(@"Get Dinner Time - %@", [NSNumber numberWithFloat:dinnerTime]);
    return [NSNumber numberWithFloat:dinnerTime];
}

- (NSNumber *)getBufferTime
{
    NSLog(@"Get Buffer Time - %@", [NSNumber numberWithFloat:bufferTime]);
    return [NSNumber numberWithFloat:bufferTime];
}

- (NSString *)getLunchMapURL
{
    return lunchMapURLString;
}

- (NSString*)getDinnerMapURL
{
    return dinnerMapURLString;
}

- (void)setLunchOrDinnerModeByTimes
{
    // Set Lunch Mode
    if (currentTime >= 0 && currentTime < dinnerTime)
    {
        [defaults setObject:@"Lunch" forKey:@"LunchOrDinner"];
        currentMode = @"Lunch";
    }
    else if (currentTime >= dinnerTime && currentTime < 24)
    {
        [defaults setObject:@"Dinner" forKey:@"LunchOrDinner"];
        currentMode = @"Dinner";
    }
    
    [defaults synchronize];
    
    NSLog(@"Current Mode - %@, Saved Mode - %@", currentMode, [defaults objectForKey:@"LunchOrDinner"]);
}

- (void)checkIfBentoArrayNeedsToBeReset
{
    NSString *strDate = [self getDateString];
    
    NSString *savedMode = [defaults objectForKey:@"LunchOrDinner"];
    
    // today's date doesn't match saved date && current mode doesn't match saved mode
    if (![strDate isEqualToString:self.strToday] && ![currentMode isEqualToString:savedMode])
    {
        [self resetBentoArray];
        
        NSLog(@"Today's Date - %@, Saved Date - %@", strDate, self.strToday);
        
        self.strToday = strDate;
        [[NSNotificationCenter defaultCenter] postNotificationName:USER_NOTIFICATION_UPDATED_MENU object:nil];
    }
}

- (NSDictionary *)getMenuInfo
{
    NSDictionary *menuInfo;
    
    if ([self isAllDay])
    {
        // check if lunch exists
        if ([self isThereLunchMenu])
            menuInfo = [defaults objectForKey:@"lunchMenuInfo"];
        
        // if no lunch, get dinner
        else if ([self isThereDinnerMenu])
            menuInfo = [defaults objectForKey:@"dinnerMenuInfo"];
    }
    
    // if not all_day
    else
    {
        // 12:00am - dinner opening (ie. 16.5) && lunch menu exists
        if (currentTime >= 0 && currentTime < dinnerTime && [defaults objectForKey:@"lunchMenuInfo"] != nil)
            menuInfo = [defaults objectForKey:@"lunchMenuInfo"];
        
        // if no lunch menu, SHOW DINNER
        else
            menuInfo = [defaults objectForKey:@"dinnerMenuInfo"];
            
        // dinner opening - 11:59pm && dinner menu exists
        if (currentTime >= dinnerTime && currentTime < 24 && [defaults objectForKey:@"dinnerMenuInfo"] != nil)
            menuInfo = [defaults objectForKey:@"dinnerMenuInfo"];
    }
    
    if (menuInfo == nil)
        return nil;
    
    return menuInfo;
}

- (NSDictionary *)getMenuItems
{
    NSDictionary *menuItems;
    
    if ([self isAllDay])
    {
        // lunch exists
        if ([self isThereLunchMenu])
        {
            NSData *data = [defaults objectForKey:@"lunchMenuItems"];
            menuItems = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
        // no lunch, dinner exists
        else if ([self isThereDinnerMenu])
        {
            NSData *data = [defaults objectForKey:@"dinnerMenuItems"];
            menuItems = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
    }
    else
    {
        // 12:00am - dinner opening (ie. 16.5)
        if (currentTime >= 0 && currentTime < dinnerTime)
        {
            NSData *data = [defaults objectForKey:@"lunchMenuItems"];
            menuItems = [NSKeyedUnarchiver unarchiveObjectWithData:data];

        // dinner opening - 11:59pm
        }
        else if (currentTime >= dinnerTime && currentTime < 24)
        {
            NSData *data = [defaults objectForKey:@"dinnerMenuItems"];
            menuItems = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
    }
    
    if (menuItems == nil)
        return nil;
    
    return menuItems;
}

- (void)getServiceAreaMapURLs {
    /*----------------- for service area URL's-------------------*/
    lunchMapURLString = self.dicInit[@"settings"][@"serviceArea_lunch_map"];
    dinnerMapURLString = self.dicInit[@"settings"][@"serviceArea_dinner_map"];
}

- (void)setGeofenceRadius {
    /*------------------set geofence------------------*/
    [self setGeofenceRadius:self.dicInit];
}

- (void)setGeofenceRadius: (NSDictionary *)initDict
{
    geofenceOrderRadiusMetersString = initDict[@"settings"][@"geofence_order_radius_meters"];
}

- (NSString *)getGeofenceRadius
{
    return geofenceOrderRadiusMetersString;
}

- (void)getServiceArea
{
    [self getServiceAreaMapURLs];
    [self setGeofenceRadius];
    
    NSString *strRequest = [NSString stringWithFormat:@"%@/servicearea", SERVER_URL];
    
    NSError *error = nil;
    NSDictionary *kmlValues = [self sendRequest:strRequest statusCode:nil error:&error];
    if (kmlValues == nil || error != nil)
        return;
    
    // Service Area
    NSString *strPoints;
    
    if ([self isAllDay])
    {
        // lunch exists
        if ([self isThereLunchMenu])
        {
            strPoints = kmlValues[@"serviceArea_lunch"][@"value"];
            NSLog(@"current time is: %f ...use lunch service area - %@", currentTime, strPoints);
        }
        // if no lunch, dinner exists
        else if ([self isThereDinnerMenu])
        {
            strPoints = kmlValues[@"serviceArea_dinner"][@"value"];
            NSLog(@"current time is: %f ...use dinner service area - %@", currentTime, strPoints);
        }
        
        /* The below 2 cases are probably unecessary...I was hardcoding the value for isAllDay to YES when there was no menu, so the app hanged */
        
        // 12:00am - dinner opening (ie. 16.5)
        else if (currentTime >= 0 && currentTime < dinnerTime)
        {
            strPoints = kmlValues[@"serviceArea_lunch"][@"value"];
            NSLog(@"current time is: %f ...use lunch service area - %@", currentTime, strPoints);
        }
        // dinner opening - 11:59pm
        else if (currentTime >= dinnerTime && currentTime < 24)
        {
            strPoints = kmlValues[@"serviceArea_dinner"][@"value"];
            NSLog(@"current time is: %f ...use dinner service area - %@", currentTime, strPoints);
        }
    }
    else
    {
        // 12:00am - dinner opening (ie. 16.5)
        if (currentTime >= 0 && currentTime < dinnerTime)
        {
            strPoints = kmlValues[@"serviceArea_lunch"][@"value"];
            NSLog(@"current time is: %f ...use lunch service area - %@", currentTime, strPoints);
        }
        // dinner opening - 11:59pm
        else if (currentTime >= dinnerTime && currentTime < 24)
        {
            strPoints = kmlValues[@"serviceArea_dinner"][@"value"];
            NSLog(@"current time is: %f ...use dinner service area - %@", currentTime, strPoints);
        }
    }
    
    if (strPoints == nil) {
        NSLog(@"WARNING!!! SERVICE AREA strPoints == nil");
    }
    
    NSArray *subStrings = [strPoints componentsSeparatedByString:@" "];
    
    // Parse String and Separate Latitude and Longitude.
    CLLocationCoordinate2D *locations = (CLLocationCoordinate2D *)malloc(sizeof(CLLocationCoordinate2D) * (subStrings.count - 1));
    
    NSInteger posCount = 0;
    for (NSInteger posIndex = 0; posIndex < subStrings.count - 1; posIndex++)
    {
        NSString *strPoint = [subStrings objectAtIndex:posIndex];
        NSArray *subComponents = [strPoint componentsSeparatedByString:@","];
        
        double latitude = 0, longitude = 0;
        for (NSInteger index = 0; index < subComponents.count; index++)
        {
            NSString *strComponent = [subComponents objectAtIndex:index];
            if (index == 0)
                longitude = [strComponent doubleValue];
            else if (index == 1)
                latitude = [strComponent doubleValue];
        }

        if (latitude == 0 && longitude == 0)
            continue;
        
        posCount ++;
        locations[posIndex] = CLLocationCoordinate2DMake(latitude, longitude);
    }

    if (posCount > 0)
        self.serviceArea = [MKPolygon polygonWithCoordinates:locations count:subStrings.count - 1];
    
    free(locations);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:USER_NOTIFICATION_UPDATED_AREA object:nil];
}

// returns bg image
- (NSURL *)getMenuImageURL
{
    if (self.menuToday == nil && self.menuNext == nil)
        return nil;
    
    NSDictionary *menuInfo = [self getMenuInfo];
    
    NSString *strMenuBack = [menuInfo objectForKey:@"bgimg"];
    if (strMenuBack == nil)
        return nil;
    
    return [NSURL URLWithString:strMenuBack];
}

- (NSString *)getMenuDateString
{
    if (self.menuToday == nil)
        return nil;
    
    NSDictionary *menuInfo = [self getMenuInfo];
    
    return [menuInfo objectForKey:@"day_text"];
}

- (NSString *)getMenuWeekdayString
{
    if (self.menuToday == nil)
        return nil;
    
    NSDictionary *menuInfo = [self getMenuInfo];
    
    NSString *strDate = [menuInfo objectForKey:@"for_date"];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *menuDate = [formatter dateFromString:strDate];
    [formatter setDateFormat:@"EEEE"];
    return [formatter stringFromDate:menuDate];
}

- (NSString *)getNextMenuDateString
{
    if (self.menuNext == nil)
        return nil;
    
    NSDictionary *menuInfo = [self getMenuInfo];
    
    return [menuInfo objectForKey:@"day_text"];
}



#pragma mark Prices and Tax
- (NSString *)getUnitPrice {
    
    // can test any amount above 0.00
    float testValue = MPTweakValue(@"Unit Price", 0.00);
    
    if (testValue > 0.00) {
        return [NSString stringWithFormat:@"%.2f", testValue];
    }
    
    // original
    return self.dicInit[@"settings"][@"price"];
}

- (NSString *)getSalePrice {
    return self.dicInit[@"settings"][@"sale_price"];
}

- (float)getDeliveryPrice {
  
    // set default delivery fee to 100.00 instead of 0.00
    // because we want to be able to test 0.00
    float testValue = MPTweakValue(@"Delivery Fee", 100.00);
    
    // we can test any number below 100
    if (testValue < 100.00) {
        return testValue;
    }
    
    return [self.dicInit[@"settings"][@"delivery_price"] floatValue];
}

- (NSString *)getTaxPercent {
    return self.dicInit[@"settings"][@"tax_percent"];
}

- (NSString *)getNextMenuWeekdayString
{
    if (self.menuNext == nil)
        return nil;
    
    NSDictionary *menuInfo;
    
    // doesn't matter lunch or dinner, just used to get next date
    if ([defaults objectForKey:@"nextLunchMenuInfo"] != nil) // if no lunch, get dinner info
        menuInfo = [defaults objectForKey:@"nextLunchMenuInfo"];
    else
        menuInfo = [defaults objectForKey:@"nextDinnerMenuInfo"];
    
    NSString *strDate = menuInfo[@"for_date"];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *menuDate = [formatter dateFromString:strDate];
    [formatter setDateFormat:@"EEEE"];
    NSString *strReturn = [formatter stringFromDate:menuDate];
    
    NSLog(@"getNextMenuDateString - %@", strReturn);
    return strReturn;
}

- (BOOL)isThereLunchMenu
{
    if ([defaults objectForKey:@"lunchMenuInfo"] != nil)
        return YES;
    else
        return NO;
}

- (BOOL)isThereDinnerMenu
{
    if ([defaults objectForKey:@"dinnerMenuInfo"] != nil)
        return YES;
    else
        return NO;
}

- (BOOL)isThereLunchNextMenu
{
    if ([defaults objectForKey:@"nextLunchMenuInfo"] != nil)
        return YES;
    else
        return NO;
}

- (BOOL)isThereDinnerNextMenu
{
    if ([defaults objectForKey:@"nextDinnerMenuInfo"] != nil)
        return YES;
    else
        return NO;
}

- (BOOL)isClosed
{
    NSDictionary *userInfo = [[DataManager shareDataManager] getUserInfo];
    if ([userInfo[@"email"] isEqualToString:@"joseph+debug@bentonow.com"]) {
        return NO;
    }
    
    if (self.dicStatus == nil)
        return YES;
    
    NSString *strOverallStatus = self.dicStatus[@"overall"][@"value"];
    if ([strOverallStatus isEqualToString:@"closed"])
        return YES;

    return NO;
}

- (BOOL)isSoldOut
{
    NSDictionary *userInfo = [[DataManager shareDataManager] getUserInfo];
    if ([userInfo[@"email"] isEqualToString:@"joseph+debug@bentonow.com"]) {
        return NO;
    }
    
    if (self.dicStatus == nil)
        return YES;
    
    NSString *strOverallStatus = self.dicStatus[@"overall"][@"value"];
    if ([strOverallStatus isEqualToString:@"sold out"])
        return YES;
    
    return NO;
}

- (BOOL)canAddDish:(NSInteger)dishID
{
    // get the quantity of dishID in menu status
    NSInteger quantity = 0;
    for (NSDictionary *menuItem in self.menuStatus)
    {
        NSInteger itemID;
        
        // get itemID
        if (![[menuItem objectForKey:@"itemId"] isEqual:[NSNull null]])
            itemID = [[menuItem objectForKey:@"itemId"] integerValue];
        
        // if selected dish id matches item id
        if (itemID == dishID)
        {
            // get the quantity of it
            if (![[menuItem objectForKey:@"qty"] isEqual:[NSNull null]])
                quantity = [[menuItem objectForKey:@"qty"] integerValue];
                break;
        }
    }
    
    if (quantity == 0)
        return YES;
    
    // check if how many of the dish exists in cart
    NSInteger currentAmount = 0;
    for (Bento *bento in self.aryBentos)
    {
        if ([bento getMainDish] == dishID)
            currentAmount ++;
        
        if ([bento getSideDish1] == dishID)
            currentAmount ++;
        
        if ([bento getSideDish2] == dishID)
            currentAmount ++;
        
        if ([bento getSideDish3] == dishID)
            currentAmount ++;
        
        if ([bento getSideDish4] == dishID)
            currentAmount ++;
    }
    
    // if the amount in cart is less than quantity, then ok to add
    if (currentAmount < quantity)
        return YES;
    
    // can't add
    return NO;
}

- (BOOL)isDishSoldOut:(NSInteger)menuID
{
    // no menu
    if (self.menuToday == nil || self.menuStatus == nil) {
        return YES;
    }
    
    // store is sold out
    if ([self isSoldOut]) {
        return YES;
    }
    
    // this is used to check whether or not the current item exists in status/menu
    // because an item can exist in an menu, but not be added to live inventory
    // the item is initialized to 0 when setting driver inventory, which makes it not appear in live inventory and status/menu
    BOOL dishExistInStatusMenu = NO;
    
    // check if dishExistInStatusMenu
    for (NSDictionary *menuItem in self.menuStatus) {
        
        NSInteger itemID; // item from status/menu
        
        if (![[menuItem objectForKey:@"itemId"] isEqual:[NSNull null]]) { // this should prevent nil being sent into NSNull
            itemID = [[menuItem objectForKey:@"itemId"] integerValue];
        }
        
        // check if item exists in status/menu
        if (itemID == menuID) {
            dishExistInStatusMenu = YES;
        }
    }
    
    // if exists, THEN check qty
    if (dishExistInStatusMenu) {
        NSInteger quantity;
        
        // check quantity of found item
        for (NSDictionary *menuItem in self.menuStatus) {
            
            NSInteger itemID;
            
            if (![[menuItem objectForKey:@"itemId"] isEqual:[NSNull null]]) {
                itemID = [[menuItem objectForKey:@"itemId"] integerValue];
            }
            
            if (itemID == menuID) {
                
                if (![[menuItem objectForKey:@"qty"] isEqual:[NSNull null]]) {
                    quantity = [[menuItem objectForKey:@"qty"] integerValue];
                }
                
                if (quantity > 0) {
                    return NO;
                }
                else {
                    return YES;
                }
            }
        }
    }
    // if not exist, then it's sold out
    else {
        return YES;
    }
    
    return NO;
}

- (void)updateProc
{
    if (self._isPaused || _isCallingApi)
        return;
    
    _isCallingApi = YES;
    
    if ([self connected])
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            // check version first
            if (self.iosCurrentVersion >= self.iosMinVersion) {
                
                [self getInit];
                [self getiOSMinAndCurrentVersions];
                [self getCurrentLunchDinnerBufferTimesInNumbersAndVersionNumbers];
                [self setLunchOrDinnerModeByTimes];
                [self checkIfBentoArrayNeedsToBeReset];
                [self getMenus];
                [self getStatus];
                [self getServiceArea];
            }
        });
        
        [self checkModeOrDateChange];
    }
    
    _isCallingApi = NO;
}

- (BOOL)connected
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    return networkStatus != NotReachable;
}

- (void)refreshStart
{
    if (_timer != nil)
        return;
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(updateProc) userInfo:nil repeats:YES];
    
    NSLog(@"Refresh Start");
}

- (void)refreshPause
{
    if (self._isPaused)
        return;
    
    self._isPaused = YES;
    [_timer invalidate];
    _timer = nil;
    
    NSLog(@"Refresh Paused");
}

- (void)refreshResume
{
    if (!self._isPaused)
        return;
    
    self._isPaused = NO;
    _timer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(updateProc) userInfo:nil repeats:YES];
    
    NSLog(@"Refresh Resumed");
}

- (void)refreshStop
{
    if (_timer == nil)
        return;
    
    [_timer invalidate];
    _timer = nil;
    
    NSLog(@"Refresh Stopped");
}

- (BOOL)isAllDay
{
    return NO;
}

- (BOOL)nextIsAllDay
{
    return NO;
}

- (NSArray *)getMainDishes:(NSString *)whatNeedsMain
{
    if (self.menuToday == nil)
        return nil;
    
    NSDictionary *menuItems;
    
    if ([whatNeedsMain isEqualToString:@"todayLunch"])
    {
        NSData *data = [defaults objectForKey:@"lunchMenuItems"];
        menuItems = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    else if ([whatNeedsMain isEqualToString:@"todayDinner"])
    {   
        NSData *data = [defaults objectForKey:@"dinnerMenuItems"];
        menuItems = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    
    NSMutableArray *arrayDishes = [[NSMutableArray alloc] init];
    for (NSDictionary *dishInfo in menuItems)
    {
        NSString *strType = [dishInfo objectForKey:@"type"];
        if ([strType isEqualToString:@"main"])
            [arrayDishes addObject:dishInfo];
    }
    
    return (NSArray *)arrayDishes;
}

- (NSArray *)getSideDishes:(NSString *)whatNeedsSides
{
    if (self.menuToday == nil)
        return nil;
    
    NSDictionary *menuItems;
    
    if ([whatNeedsSides isEqualToString:@"todayLunch"])
    {
        NSData *data = [defaults objectForKey:@"lunchMenuItems"];
        menuItems = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    else if ([whatNeedsSides isEqualToString:@"todayDinner"])
    {
        NSData *data = [defaults objectForKey:@"dinnerMenuItems"];
        menuItems = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    
    NSMutableArray *arrayDishes = [[NSMutableArray alloc] init];
    for (NSDictionary *dishInfo in menuItems)
    {
        NSString *strType = [dishInfo objectForKey:@"type"];
        if ([strType isEqualToString:@"side"])
            [arrayDishes addObject:dishInfo];
    }
    
    return (NSArray *)arrayDishes;
}

- (NSArray *)getAddons:(NSString *)whatNeedsAddons
{
    if (self.menuToday == nil) {
        return nil;
    }
    
    NSDictionary *menuItems;
    
    if ([whatNeedsAddons isEqualToString:@"todayLunch"]) {
        NSData *data = [defaults objectForKey:@"lunchMenuItems"];
        menuItems = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    else if ([whatNeedsAddons isEqualToString:@"todayDinner"]) {
        NSData *data = [defaults objectForKey:@"dinnerMenuItems"];
        menuItems = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    
    NSMutableArray *arrayDishes = [[NSMutableArray alloc] init];
    for (NSDictionary *dishInfo in menuItems) {
        NSString *strType = [dishInfo objectForKey:@"type"];
        if ([strType isEqualToString:@"addon"]) {
            [arrayDishes addObject:dishInfo];
        }
    }
    
    return (NSArray *)arrayDishes;
}

- (NSArray *)getNextMainDishes:(NSString *)whatNeedsMain
{
    if (self.menuNext == nil)
        return nil;
    
    NSDictionary *menuItems;
    
    if ([whatNeedsMain isEqualToString:@"nextLunchPreview"])
    {
        NSData *data = [defaults objectForKey:@"nextLunchMenuItems"];
        menuItems = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    else if ([whatNeedsMain isEqualToString:@"nextDinnerPreview"])
    {
        NSData *data = [defaults objectForKey:@"nextDinnerMenuItems"];
        menuItems = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    
    NSMutableArray *arrayDishes = [[NSMutableArray alloc] init];
    for (NSDictionary *dishInfo in menuItems)
    {
        NSString *strType = [dishInfo objectForKey:@"type"];
        if ([strType isEqualToString:@"main"])
            [arrayDishes addObject:dishInfo];
    }
    
    return (NSArray *)arrayDishes;
}

- (NSArray *)getNextSideDishes:(NSString *)whatNeedsSides
{
    if (self.menuNext == nil)
        return nil;
    
    NSDictionary *menuItems;
    
    if ([whatNeedsSides isEqualToString:@"nextLunchPreview"])
    {
        NSData *data = [defaults objectForKey:@"nextLunchMenuItems"];
        menuItems = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    else if ([whatNeedsSides isEqualToString:@"nextDinnerPreview"])
    {
        NSData *data = [defaults objectForKey:@"nextDinnerMenuItems"];
        menuItems = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    
    NSMutableArray *arrayDishes = [[NSMutableArray alloc] init];
    for (NSDictionary *dishInfo in menuItems)
    {
        NSString *strType = [dishInfo objectForKey:@"type"];
        if ([strType isEqualToString:@"side"])
            [arrayDishes addObject:dishInfo];
    }
    
    return (NSArray *)arrayDishes;
}

- (NSArray *)getNextAddons:(NSString *)whatNeedsAddons
{
    if (self.menuNext == nil) {
        return nil;
    }
    
    NSDictionary *menuItems;
    
    if ([whatNeedsAddons isEqualToString:@"nextLunchPreview"]) {
        NSData *data = [defaults objectForKey:@"nextLunchMenuItems"];
        menuItems = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    else if ([whatNeedsAddons isEqualToString:@"nextDinnerPreview"]) {
        NSData *data = [defaults objectForKey:@"nextDinnerMenuItems"];
        menuItems = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    
    NSMutableArray *arrayDishes = [[NSMutableArray alloc] init];
    for (NSDictionary *dishInfo in menuItems) {
        NSString *strType = [dishInfo objectForKey:@"type"];
        if ([strType isEqualToString:@"addon"]) {
            [arrayDishes addObject:dishInfo];
        }
    }
    
    return (NSArray *)arrayDishes;
}

- (NSDictionary *)getMainDish:(NSInteger)mainDishID
{
    if (self.menuToday == nil)
        return nil;
    
    NSDictionary *menuItems = [self getMenuItems];
    
    for (NSDictionary *dishInfo in menuItems)
    {
        NSString *strType = [dishInfo objectForKey:@"type"];
        NSInteger menuIndex = [[dishInfo objectForKey:@"itemId"] integerValue];
        if ([strType isEqualToString:@"main"] && menuIndex == mainDishID)
            return dishInfo;
    }
    
    return nil;
}

- (NSDictionary *)getSideDish:(NSInteger)sideDishID;
{
    if (self.menuToday == nil)
        return nil;
    
    NSDictionary *menuItems = [self getMenuItems];
    
    for (NSDictionary *dishInfo in menuItems)
    {
        NSString *strType = [dishInfo objectForKey:@"type"];
        NSInteger menuIndex = [[dishInfo objectForKey:@"itemId"] integerValue];
        if ([strType isEqualToString:@"side"] && menuIndex == sideDishID)
            return dishInfo;
    }
    
    return nil;
}

- (MKPolygon *)getPolygon
{
    return self.serviceArea;
}

- (BOOL)checkLocation:(CLLocationCoordinate2D)location
{
    if (self.serviceArea == nil) {
        return NO;
    }
    
    MKMapPoint mapPoint = MKMapPointForCoordinate(location);
    
    CGMutablePathRef mpr = CGPathCreateMutable();
    
    MKMapPoint *polygonPoints = self.serviceArea.points;
    size_t nCount = self.serviceArea.pointCount;
    
    for (int p = 0; p < nCount; p++) {
        
        MKMapPoint mp = polygonPoints[p];
        
        if (p == 0) {
            CGPathMoveToPoint(mpr, NULL, mp.x, mp.y);
        }
        else {
            CGPathAddLineToPoint(mpr, NULL, mp.x, mp.y);
        }
    }
    
    CGPoint mapPointAsCGP = CGPointMake(mapPoint.x, mapPoint.y);
    
    BOOL pointIsInPolygon = CGPathContainsPoint(mpr, NULL, mapPointAsCGP, FALSE);
    CGPathRelease(mpr);
    
    return pointIsInPolygon;
}

- (NSInteger)getTotalBentoCount
{
    if (self.aryBentos == nil)
        return 0;
    
    return self.aryBentos.count;
}

- (NSInteger)getCompletedBentoCount
{
    NSInteger completedCount = 0;
    if (self.aryBentos == nil)
        return completedCount;
    
    for (Bento *bento in self.aryBentos)
    {
        if ([bento isCompleted])
            completedCount++;
    }
    
    return completedCount;
}

- (Bento *)getCurrentBento
{
    if (self.aryBentos.count == 0)
        return nil;

    _currentIndex = self.aryBentos.count - 1;
    
    return self.aryBentos[_currentIndex];
}

- (void)setCurrentBento:(Bento *)bento
{
    if (self.aryBentos == nil || self.aryBentos.count == 0)
        return;
    
    NSInteger bentoIndex = [self.aryBentos indexOfObject:bento];
    
    /*added this to fix issue with editing bentos*/
    [self.aryBentos addObject:bento];
    [self.aryBentos removeObjectAtIndex:bentoIndex];
    [self saveBentoArray];
    /**/
    
    if (bentoIndex == NSNotFound)
        return;
    
    _currentIndex = bentoIndex;
}

- (Bento *)getBento:(NSInteger)bentoIndex
{
    if (bentoIndex < 0 || bentoIndex >= self.aryBentos.count)
        return nil;
    
    return [self.aryBentos objectAtIndex:bentoIndex];
}

- (Bento *)getLastBento
{
    if (self.aryBentos == nil || self.aryBentos.count == 0)
        return nil;
    
    return [self.aryBentos lastObject];
}

- (void)addNewBento
{
    // remove all empty bentos before adding new bento
    for (NSInteger index = 0; index < self.aryBentos.count; index++)
    {
        Bento *bento = [[BentoShop sharedInstance] getBento:index];
        if (![bento isCompleted])
            [self removeBento:bento];
    }

    Bento *newBento = [[Bento alloc] init];
    [self.aryBentos addObject:newBento];
    _currentIndex = self.aryBentos.count - 1;
    [self saveBentoArray];
}

- (void)removeBento:(Bento *)bento
{
    NSUInteger bentoIndex = [self.aryBentos indexOfObject:bento];
    if (bentoIndex == NSNotFound)
        return;
    
    if (bentoIndex == _currentIndex)
        _currentIndex = NSNotFound;
    
    [self.aryBentos removeObjectAtIndex:bentoIndex];
    [self saveBentoArray];
}

- (void)loadBentoArray
{
    NSArray *savedArray  = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"bento_array"];
    self.aryBentos = [NSMutableArray arrayWithArray:savedArray];
    self.strToday = [[NSUserDefaults standardUserDefaults] objectForKey:@"bento_date"];
}

- (void)saveBentoArray
{
    [[NSUserDefaults standardUserDefaults] rm_setCustomObject:self.aryBentos forKey:@"bento_array"];
    [[NSUserDefaults standardUserDefaults] setObject:self.strToday forKey:@"bento_date"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)resetBentoArray
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // reset only if not nil and not empty
        if (self.aryBentos.count) {
            [self.aryBentos removeAllObjects];
            
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"arySoldOutItems"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [[AddonList sharedInstance] emptyList];
        }
    });
}

#pragma mark Response to State Change

- (void)checkModeOrDateChange
{
    // lunch/dinner times changed, reset
    // set currentMode
    
    // 12:00am - dinner opening (ie. 16.5)
    if (currentTime >= 0 && currentTime < dinnerTime) {
        [[NSUserDefaults standardUserDefaults] setObject:@"LunchMode" forKey:@"NewLunchOrDinnerMode"];
    }
    // dinner opening - 11:59pm
    else if (currentTime >= dinnerTime && currentTime < 24) {
        [[NSUserDefaults standardUserDefaults] setObject:@"DinnerMode" forKey:@"NewLunchOrDinnerMode"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"checkModeOrDateChange" object:nil];
}

- (BOOL)didModeOrDateChange
{
    NSString *originalDateString = [[NSUserDefaults standardUserDefaults] objectForKey:@"OriginalDateString"];
    NSString *newDateString = [self getMenuDateString];
    
    NSLog(@"orig - %@, new - %@", originalDateString, newDateString);
    
    BOOL shouldReset = NO;
    
    // if nothing changed, most likely because there's no menu for today, date string returns nil
    if (originalDateString == nil && newDateString == nil) {
        [[NSUserDefaults standardUserDefaults] setObject:newDateString forKey:@"OriginalDateString"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // should not reset
    }
    // if date changed - or if mode changes to/from nil menu (meaning app could not get the date string from nil menu)
    else if (![originalDateString isEqualToString:newDateString]) {
        [[NSUserDefaults standardUserDefaults] setObject:newDateString forKey:@"OriginalDateString"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    
        [self resetBentoArray];
    
        shouldReset = YES;
    }
    
    // if mode changed, and is not all-day
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"OriginalLunchOrDinnerMode"] isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"NewLunchOrDinnerMode"]] && [[BentoShop sharedInstance] isAllDay] == NO) {
        
        // reset originalLunchOrDinnerMode with newLunchOrDinnerMode
        [[NSUserDefaults standardUserDefaults] setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"NewLunchOrDinnerMode"]
                                                  forKey:@"OriginalLunchOrDinnerMode"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self resetBentoArray];
        
        shouldReset = YES;
    }
    
    // reset auto view add-ons flag
    if (shouldReset) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"AutoShowAddons"];
    }
    
    return shouldReset;
}

- (void)setSignInStatus:(BOOL)status
{
    signedIn = status;
}

- (BOOL)isSignedIn
{
    return signedIn;
}

- (BOOL)is4PodMode
{
//    NSString *podMode = self.dicInit[@"settings"][@"pod_mode"];
//    
//    if (podMode != nil || ![podMode isEqualToString:@""]) {
//        if ([podMode integerValue] == 4) {
//            return YES;
//        }
//    }
//    
//    return NO;
    
    return YES;
}

@end
