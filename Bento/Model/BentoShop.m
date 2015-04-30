//
//  BentoShop.m
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "BentoShop.h"

#import "DataManager.h"
#import "AppStrings.h"

#import "SDWebImagePrefetcher.h"
#import "NSUserDefaults+RMSaveCustomObject.h"

@interface BentoShop ()

@property (nonatomic, retain) NSString *strToday;
@property (nonatomic, retain) NSDictionary *dicStatus;
@property (nonatomic, retain) NSDictionary *menuToday;
@property (nonatomic, retain) NSDictionary *menuNext;
@property (nonatomic, retain) NSArray *menuStatus;
@property (nonatomic, retain) MKPolygon *serviceArea;
@property (nonatomic, retain) NSMutableArray *aryBentos;

@property (nonatomic, assign) BOOL prevClosed;
@property (nonatomic, assign) BOOL prevSoldOut;

@end

@implementation BentoShop
{
    NSString *originalStatus;
}

static BentoShop *_shareInstance;

+ (BentoShop *)sharedInstance
{
    @synchronized(self) {
        
        if (_shareInstance == nil)
        {
            _shareInstance = [[BentoShop alloc] init];
        }
    }
    
    return _shareInstance;
}

+ (void)releaseInstance
{
    if (_shareInstance != nil)
    {
        _shareInstance = nil;
    }
}

- (id) init
{
    if ( (self = [super init]) )
    {
        self.prevClosed = NO;
        self.prevSoldOut = NO;
        
        self.strToday = nil;
        self.dicStatus = nil;
        self.menuToday = nil;
        self.menuNext = nil;
        self.menuStatus = nil;
        self.serviceArea = nil;
        
        _isPaused = NO;
        _isCallingApi = NO;
        _currentIndex = NSNotFound;
        
        [self loadBentoArray];
        if (self.aryBentos == nil)
            self.aryBentos = [[NSMutableArray alloc] init];
    }
    
    // set original status to empty string when app launches the first time
    originalStatus = @"";
    
    return self;
}

- (id)sendRequest:(NSString *)strRequest statusCode:(NSInteger *)statusCode error:(NSError **)error
{
    if (strRequest == nil || strRequest.length == 0)
        return nil;
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:strRequest]];
    NSURLResponse *response = nil;
    
    if (error != nil)
        *error = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:error];
    if (data == nil)
        return nil;
    
    if (statusCode != nil && [response isKindOfClass:[NSHTTPURLResponse class]])
        *statusCode = [(NSHTTPURLResponse *)response statusCode];
    
    if (*error != nil)
        return nil;
    
    if (statusCode != nil && *statusCode != 200)
        return nil;
    
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
}

- (void)getStatus
{
    NSString *strRequest = [NSString stringWithFormat:@"%@/status/overall", SERVER_URL];
    
    NSError *error = nil;
    self.dicStatus = [self sendRequest:strRequest statusCode:nil error:&error];
    
    
    if (originalStatus.length == 0) {
        originalStatus = self.dicStatus[@"value"];
    }
    
    NSString *newStatus = self.dicStatus[@"value"];
    
    if (![originalStatus isEqualToString:newStatus]) {
        
        [[AppStrings sharedInstance] getAppStrings];
        
        originalStatus = @"";
        
        NSLog(@"STATUS CHANGED!!! GET APP STRINGS!!!");
    }
    
    NSLog(@"originalStatus - %@, newStatus - %@", originalStatus, newStatus);
    
    strRequest = [NSString stringWithFormat:@"%@/status/menu", SERVER_URL];
    
    self.menuStatus = [self sendRequest:strRequest statusCode:nil error:&error];
    
//    NSLog(@"menuStatus - %@", self.menuStatus);
    
    BOOL isClosed = [self isClosed];
    BOOL isSoldOut = [self isSoldOut];
    
    NSLog(@"isClosed - %id, isSoldOut - %id", isClosed, isSoldOut);
    
    if ([self isClosed])
        [self getNextMenus];
    
    if (self.prevClosed != isClosed || self.prevSoldOut != isSoldOut) {
        [[NSNotificationCenter defaultCenter] postNotificationName:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    }
    
    self.prevClosed = isClosed;
    self.prevSoldOut = isSoldOut;
    
    if ([self isClosed] && ![[DataManager shareDataManager] isAdminUser])
        [self resetBentoArray];
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
    
    NSLog(@"getDateString - %@", strDate);
    
    return strDate;
}

- (void)resetBentoArray
{
    [self.aryBentos removeAllObjects];
}

- (void)prefetchImages:(NSDictionary *)menuInfo
{
    if (menuInfo == nil)
        return;
    
    NSMutableArray *urls = [[NSMutableArray alloc] init];
    NSDictionary *menuDetailInfo = [menuInfo objectForKey:@"Menu"];
    if (menuDetailInfo != nil)
    {
        NSString *strMenuBack = [menuInfo objectForKey:@"bgimg"];
        if (strMenuBack != nil && [strMenuBack isKindOfClass:[NSString class]] && strMenuBack.length > 0)
            [urls addObject:[NSURL URLWithString:strMenuBack]];
    }
    
    NSArray *aryDishes = [menuInfo objectForKey:@"MenuItems"];
    if (aryDishes != nil && [aryDishes isKindOfClass:[NSArray class]] && aryDishes.count > 0)
    {
        for (NSDictionary *dishInfo in aryDishes)
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
    self.menuToday = [self sendRequest:strRequest statusCode:nil error:&error];
    
    [self prefetchImages:self.menuToday];
    
    if (![strDate isEqualToString:self.strToday])
    {
        [self resetBentoArray];
        
        self.strToday = strDate;
        [[NSNotificationCenter defaultCenter] postNotificationName:USER_NOTIFICATION_UPDATED_MENU object:nil];
    }
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
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:[NSDate date]];
    NSInteger hour = [components hour];
    
    NSLog(@"CURRENT HOUR - %ld", (long)hour);
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd"];
    NSString *strDate = [formatter stringFromDate:currentDate];
    
    if (hour < 21) // before 9pm
    {
        NSString *strRequest = [NSString stringWithFormat:@"%@/menu/%@", SERVER_URL, strDate];
        
        NSError *error = nil;
        NSInteger statusCode = 0;
        self.menuNext = [self sendRequest:strRequest statusCode:&statusCode error:&error];
        
        if (statusCode == 404)
        {
            strRequest = [NSString stringWithFormat:@"%@/menu/next/%@", SERVER_URL, strDate];
            self.menuNext = [self sendRequest:strRequest statusCode:&statusCode error:&error];
        }
    }
    else
    {
        NSString *strRequest = [NSString stringWithFormat:@"%@/menu/next/%@", SERVER_URL, strDate];
        
        NSError *error = nil;
        NSInteger statusCode = 0;
        self.menuNext = [self sendRequest:strRequest statusCode:&statusCode error:&error];
    }

    [self prefetchImages:self.menuNext];
    [[NSNotificationCenter defaultCenter] postNotificationName:USER_NOTIFICATION_UPDATED_NEXTMENU object:nil];
}

- (void)getServiceArea
{
    NSString *strRequest = [NSString stringWithFormat:@"%@/servicearea", SERVER_URL];
    
    NSError *error = nil;
    NSDictionary *kmlValues = [self sendRequest:strRequest statusCode:nil error:&error];
    if (kmlValues == nil || error != nil)
        return;
    
    NSString *strPoints = [kmlValues objectForKey:@"value"];
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

- (NSURL *)getMenuImageURL
{
    if (self.menuToday == nil && self.menuNext == nil)
        return nil;
    
    NSDictionary *menuInfo = [self.menuToday objectForKey:@"Menu"];
    if (menuInfo == nil)
        menuInfo = [self.menuNext objectForKey:@"Menu"];
    
    if (menuInfo == nil)
        return nil;
    
    NSString *strMenuBack = [menuInfo objectForKey:@"bgimg"];
    if (strMenuBack == nil)
        return nil;
    
    return [NSURL URLWithString:strMenuBack];
}

- (NSString *)getMenuDateString
{
    if (self.menuToday == nil)
        return nil;
    
    NSDictionary *menuInfo = [self.menuToday objectForKey:@"Menu"];
    if (menuInfo == nil)
        return nil;
    
    return [menuInfo objectForKey:@"day_text"];
}

- (NSString *)getMenuWeekdayString
{
    if (self.menuToday == nil)
        return nil;
    
    NSDictionary *menuInfo = [self.menuToday objectForKey:@"Menu"];
    if (menuInfo == nil)
        return nil;
    
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
    
    NSDictionary *menuInfo = [self.menuNext objectForKey:@"Menu"];
    if (menuInfo == nil)
        return nil;
    
    return [menuInfo objectForKey:@"day_text"];
}

- (NSString *)getNextMenuWeekdayString
{
    if (self.menuNext == nil)
        return nil;
    
    NSDictionary *menuInfo = [self.menuNext objectForKey:@"Menu"];
    if (menuInfo == nil)
        return nil;
    
    NSString *strDate = [menuInfo objectForKey:@"for_date"];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *menuDate = [formatter dateFromString:strDate];
    [formatter setDateFormat:@"EEEE"];
    NSString *strReturn = [formatter stringFromDate:menuDate];
    return strReturn;
}

- (BOOL)isClosed
{
    if (self.dicStatus == nil)
        return YES;
    
    NSString *strOverallStatus = [self.dicStatus objectForKey:@"value"];
    if ([strOverallStatus isEqualToString:@"closed"])
        return YES;

    return NO;
}

- (BOOL)isSoldOut
{
//    if (self.menuStatus == nil)
//        return YES;
//    
//    for (NSDictionary *menuItem in self.menuStatus)
//    {
//        NSInteger quantity = [[menuItem objectForKey:@"qty"] integerValue];
//        if (quantity > 0)
//            return NO;
//    }
//    
//    return YES;
    if (self.dicStatus == nil)
        return YES;
    
    NSString *strOverallStatus = [self.dicStatus objectForKey:@"value"];
    if ([strOverallStatus isEqualToString:@"sold out"])
        return YES;
    
    return NO;
}

- (BOOL)canAddDish:(NSInteger)dishID
{
    NSInteger quantity = 0;
    for (NSDictionary *menuItem in self.menuStatus)
    {
        NSInteger itemID = [[menuItem objectForKey:@"itemId"] integerValue];
        if (itemID == dishID)
        {
            quantity = [[menuItem objectForKey:@"qty"] integerValue];
            break;
        }
    }
    
    if (quantity == 0)
        return YES;
    
    NSInteger currentAmount = 0;
    for (Bento *bento in self.aryBentos)
    {
//        if (![bento isCompleted])
//            continue;
        
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
    
    if (currentAmount < quantity)
        return YES;
    
    return NO;
}

- (BOOL)isDishSoldOut:(NSInteger)menuID
{
    if (self.menuToday == nil || self.menuStatus == nil)
        return YES;
    
    if ([self isSoldOut])
        return YES;

    for (NSDictionary *menuItem in self.menuStatus)
    {
        NSInteger itemID = [[menuItem objectForKey:@"itemId"] integerValue];
        if (itemID == menuID)
        {
            NSInteger quantity = [[menuItem objectForKey:@"qty"] integerValue];
            
            if (quantity > 0)
                return NO;
            
            return YES;
        }
    }
    
    return NO;
}

- (void)updateProc
{
    if (_isPaused || _isCallingApi)
        return;
    
    _isCallingApi = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self getMenus];
        [self getStatus];
        [self getServiceArea];
    });
    
    _isCallingApi = NO;
}

- (void)refreshStart
{
    if (_timer != nil)
        return;
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(updateProc) userInfo:nil repeats:YES];
}

- (void)refreshPause
{
    if (_isPaused)
        return;
    
    _isPaused = YES;
    [_timer invalidate];
    _timer = nil;
}

- (void)refreshResume
{
    if (!_isPaused)
        return;
    
    _isPaused = NO;
    _timer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(updateProc) userInfo:nil repeats:YES];
}

- (void)refreshStop
{
    if (_timer == nil)
        return;
    
    [_timer invalidate];
    _timer = nil;
}

- (NSArray *)getMainDishes
{
    if (self.menuToday == nil)
        return nil;
    
    NSArray *menuItems = [self.menuToday objectForKey:@"MenuItems"];
    if (menuItems == nil)
        return nil;
    
    NSMutableArray *arrayDishes = [[NSMutableArray alloc] init];
    for (NSDictionary *dishInfo in menuItems)
    {
        NSString *strType = [dishInfo objectForKey:@"type"];
        if ([strType isEqualToString:@"main"])
            [arrayDishes addObject:dishInfo];
    }
    
    return (NSArray *)arrayDishes;
}

- (NSArray *)getSideDishes
{
    if (self.menuToday == nil)
        return nil;
    
    NSArray *menuItems = [self.menuToday objectForKey:@"MenuItems"];
    if (menuItems == nil)
        return nil;
    
    NSMutableArray *arrayDishes = [[NSMutableArray alloc] init];
    for (NSDictionary *dishInfo in menuItems)
    {
        NSString *strType = [dishInfo objectForKey:@"type"];
        if ([strType isEqualToString:@"side"])
            [arrayDishes addObject:dishInfo];
    }
    
    return (NSArray *)arrayDishes;
}

- (NSArray *)getNextMainDishes
{
    if (self.menuNext == nil)
        return nil;
    
    NSArray *menuItems = [self.menuNext objectForKey:@"MenuItems"];
    if (menuItems == nil)
        return nil;
    
    NSMutableArray *arrayDishes = [[NSMutableArray alloc] init];
    for (NSDictionary *dishInfo in menuItems)
    {
        NSString *strType = [dishInfo objectForKey:@"type"];
        if ([strType isEqualToString:@"main"])
            [arrayDishes addObject:dishInfo];
    }
    
    return (NSArray *)arrayDishes;
}

- (NSArray *)getNextSideDishes
{
    if (self.menuNext == nil)
        return nil;
    
    NSArray *menuItems = [self.menuNext objectForKey:@"MenuItems"];
    if (menuItems == nil)
        return nil;
    
    NSMutableArray *arrayDishes = [[NSMutableArray alloc] init];
    for (NSDictionary *dishInfo in menuItems)
    {
        NSString *strType = [dishInfo objectForKey:@"type"];
        if ([strType isEqualToString:@"side"])
            [arrayDishes addObject:dishInfo];
    }
    
    return (NSArray *)arrayDishes;
}

- (NSDictionary *)getMainDish:(NSInteger)mainDishID
{
    if (self.menuToday == nil)
        return nil;
    
    NSArray *menuItems = [self.menuToday objectForKey:@"MenuItems"];
    if (menuItems == nil)
        return nil;
    
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
    
    NSArray *menuItems = [self.menuToday objectForKey:@"MenuItems"];
    if (menuItems == nil)
        return nil;
    
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
    if (self.serviceArea == nil)
        return NO;
    
    MKMapPoint mapPoint = MKMapPointForCoordinate(location);
    
    CGMutablePathRef mpr = CGPathCreateMutable();
    
    MKMapPoint *polygonPoints = self.serviceArea.points;
    size_t nCount = self.serviceArea.pointCount;
    
    for (int p = 0; p < nCount; p++)
    {
        MKMapPoint mp = polygonPoints[p];
        
        if (p == 0)
            CGPathMoveToPoint(mpr, NULL, mp.x, mp.y);
        else
            CGPathAddLineToPoint(mpr, NULL, mp.x, mp.y);
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
            completedCount ++;
    }
    
    return completedCount;
}

- (Bento *)getCurrentBento
{
    if (self.aryBentos.count == 0)
        return nil;
    
    if (_currentIndex == NSNotFound)
        _currentIndex = self.aryBentos.count - 1;
    
    return [self.aryBentos objectAtIndex:_currentIndex];
}

- (void)setCurrentBento:(Bento *)bento
{
    if (self.aryBentos == nil || self.aryBentos.count == 0)
        return;
    
    NSInteger bentoIndex = [self.aryBentos indexOfObject:bento];
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

@end
