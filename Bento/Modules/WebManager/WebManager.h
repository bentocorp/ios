//
//  WebManager.h
//  BrighterLink
//
//  Created by mobile master on 11/5/14.
//  Copyright (c) 2014 Brightergy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MKNetworkKit.h"

#define HostAddress @"https://api.bentonow.com"

typedef enum : NSUInteger {
    GET = 0,
    POST,
    PUT,
    PATCH,
    DELETE
} Method;

@interface WebManager : NSObject
{
    MKNetworkEngine* m_engine;
    NSString* m_apiURL;
}

typedef void (^SuccessBlock)(MKNetworkOperation* networkOperation);
typedef void (^ErrorBlock)(MKNetworkOperation *errorOp, NSError* error);

@property (nonatomic) BOOL ProcessError;

- (void)AsyncProcess:(NSString *)strAPIName method:(Method)method parameters:(NSDictionary*)params success:(SuccessBlock)success failure:(ErrorBlock)failure isJSON:(BOOL)isJSON;

//############################################################# User define methods ############################################################
- (void)AsyncRequest:(NSString *)strRequest method:(Method)method parameters:(NSDictionary*)params success:(SuccessBlock)success failure:(ErrorBlock)failure isJSON:(BOOL)isJSON;


//############################################################# User define methods ############################################################
/*
//------------------------------------- User -------------------------------------
-(void)Login:(NSString*)email password:(NSString*)password success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)CreateBP:(NSString*)secretKey userInfo:(NSDictionary*)userInfo success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)CreateUser:(NSDictionary*)userObj sfdcAccount:(NSString*)sfdcAccountId success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)CreateAccountWithSF:(NSDictionary*)account member:(NSDictionary*)member success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)DeleteUser:(NSString*)userId success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)GetMembers:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)GetAllAdmins:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)GetAppConfiguration:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)GetEnphaseAuthURL:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)GetEnphaseInventory:(NSString*)systemID success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)GetEnphaseSystems:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)SearchUsers:(NSString*)searchKey success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)GetUserInfoById:(NSString*)userId success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)UpdateUserInfo:(NSDictionary*)param success:(SuccessBlock)success failure:(ErrorBlock)failure;
//--------------------------------------------------------------------------------

//------------------------------------- Tags -------------------------------------
-(void)AddAccessibleTag:(NSString*)userId object:(NSDictionary*)accessibleTagObj success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)CheckTagDeletable:(NSString*)tagId success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)CreateTag:(NSDictionary*)tagObj success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)CreateTagRule:(NSDictionary*)ruleObj success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)DeleteTag:(NSString*)tagId success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)DeleteTagRule:(NSString*)ruleId success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)EditTag:(NSDictionary*)tagObj tagId:(NSString*)tagId success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)EditTagRule:(NSDictionary*)ruleObj ruleId:(NSString*)ruleId success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)GetTagRules:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)GetTagById:(NSString*)tagId success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)GetUserTags:(NSString*)userId success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)RemoveAccessibleTag:(NSString*)accessibleTagId userID:(NSString*)userId success:(SuccessBlock)success failure:(ErrorBlock)failure;
//--------------------------------------------------------------------------------

//------------------------------------- Assets -----------------------------------
-(void)UploadUserPicture:(NSData*)fileData success:(SuccessBlock)success failure:(ErrorBlock)failure;
//--------------------------------------------------------------------------------

//------------------------------------- Accounts ---------------------------------
-(void)CreateAccount:(NSDictionary*)account member:(NSDictionary*)member success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)GetAllAccounts:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)UpdateAccount:(NSDictionary*)account success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)VerifyAccountCName:(NSString*)cName success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)DeleteAccount:(NSString*)accountId success:(SuccessBlock)success failure:(ErrorBlock)failure;
//--------------------------------------------------------------------------------

//------------------------------------- Others -----------------------------------
-(void)GetDevices:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)GetManufacturers:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)GetSFDCAccounts:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)GetUtilityProviders:(NSString*)findNameMask success:(SuccessBlock)success failure:(ErrorBlock)failure;
//--------------------------------------------------------------------------------

//------------------------------------- Dashboard -------------------------------------
-(void)GetAllDashboards:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)CreateDashboard:(NSDictionary *)dashboardObj success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)UpdateDashboard:(NSString *)dashboardId param:(NSDictionary *)dashboardObj success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)DeleteDashboard:(NSString *)dashboardId success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)GetDashboard:(NSString *)dashboardId success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)GetMetricsInDashboard:(NSString *)dashboardId success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)GetAllSegmentsInDashboard:(NSString *)dashboardId success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)DeleteSegmentInDashboard:(NSString *)dashboardId segment:(NSString *)segment success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)AddNewSegmentInDashboard:(NSString *)dashboardId param:(NSArray *)param success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)UpdateSegmentInDashboard:(NSString *)dashboardId param:(NSArray *)param success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)AddNewWidget:(NSString *)dashboardId param:(NSDictionary *)param success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)UpdateNewWidget:(NSString *)dashboardId widgetId:(NSString *)widgetId param:(NSDictionary *)param success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)DeleteWidget:(NSString *)dashboardId widget:(NSString *)widgetId success:(SuccessBlock)success failure:(ErrorBlock)failure;
-(void)GetDashboardWidgetDatas:(NSString *)dashboardId success:(SuccessBlock)success failure:(ErrorBlock)failure;

//--------------------------------------------------------------------------------

//##############################################################################################################################################
*/
@end
