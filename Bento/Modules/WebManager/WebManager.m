//
//  WebManager.m
//  BrighterLink
//
//  Created by mobile master on 11/5/14.
//  Copyright (c) 2014 Brightergy. All rights reserved.
//

// Read the following link to know in more detail
// https://github.com/AFNetworking/AFNetworking

#import "WebManager.h"

@implementation WebManager

-(id)init
{
    if (self = [super init])
    {
        m_apiURL = @"https://api.bentonow.com";
        m_engine = [[MKNetworkEngine alloc] init];
    }
    return self;
}

-(void)dealloc
{
    [m_engine cancelAllOperations];
}

-(void)AsyncProcess:(NSString *)strAPIName method:(Method)method parameters:(NSDictionary*)params success:(SuccessBlock)success failure:(ErrorBlock)failure isJSON:(BOOL)isJSON
{
    m_apiURL = [NSString stringWithFormat:@"%@%@", HostAddress, strAPIName];
    
    NSString* strMethod = @"GET";
    switch (method) {
        case GET:
            strMethod = @"GET";
            break;
        case POST:
            strMethod = @"POST";
            break;
        case PUT:
            strMethod = @"PUT";
            break;
        case PATCH:
            strMethod = @"PATCH";
            break;
        case DELETE:
            strMethod = @"DELETE";
            break;
        default:
            break;
    }
    
    if (params && [params isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"%@", [params jsonEncodedKeyValueString]);
    }
    
    NSArray *aryParams = nil;
    if ([params isKindOfClass:[NSArray class]])
    {
        aryParams = (NSArray *)params;
        params = nil;
    }
    
    MKNetworkOperation* op = [[MKNetworkOperation alloc] initWithURLString:m_apiURL params:params httpMethod:strMethod];
    if (isJSON)
        [op setPostDataEncoding:MKNKPostDataEncodingTypeJSON];

    if (aryParams != nil)
    {
        [op setCustomPostDataEncodingHandler:^NSString *(NSDictionary *postDataDict) {
            
            NSDictionary *dicParams = nil;
            
            if (aryParams.count > 0)dicParams = [aryParams objectAtIndex:0];
            
            NSString *postString = [NSString stringWithFormat:@"\[%@\]", [dicParams jsonEncodedKeyValueString]];
            
            return postString;
            
        } forType:@"application/json"];
    }
    
    [op addCompletionHandler:success errorHandler:failure];
    
    [m_engine enqueueOperation:op];
}

//############################################################# User define methods ############################################################
- (void)AsyncRequest:(NSString *)strRequest method:(Method)method parameters:(NSDictionary *)params success:(SuccessBlock)success failure:(ErrorBlock)failure isJSON:(BOOL)isJSON
{
    m_apiURL = strRequest;

    NSString* strMethod = @"GET";
    switch (method) {
        case GET:
            strMethod = @"GET";
            break;
        case POST:
            strMethod = @"POST";
            break;
        case PUT:
            strMethod = @"PUT";
            break;
        case PATCH:
            strMethod = @"PATCH";
            break;
        case DELETE:
            strMethod = @"DELETE";
            break;
        default:
            break;
    }
    
    if (params && [params isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"%@", [params jsonEncodedKeyValueString]);
    }
    
    NSArray *aryParams = nil;
    if ([params isKindOfClass:[NSArray class]])
    {
        aryParams = (NSArray *)params;
        params = nil;
    }
    
    MKNetworkOperation* op = [[MKNetworkOperation alloc] initWithURLString:m_apiURL params:params httpMethod:strMethod];
    if (isJSON)
        [op setPostDataEncoding:MKNKPostDataEncodingTypeJSON];
    
    if (aryParams != nil)
    {
        [op setCustomPostDataEncodingHandler:^NSString *(NSDictionary *postDataDict) {
            
            NSDictionary *dicParams = nil;
            
            if (aryParams.count > 0)dicParams = [aryParams objectAtIndex:0];
            
            NSString *postString = [NSString stringWithFormat:@"\[%@\]", [dicParams jsonEncodedKeyValueString]];
            
            return postString;
            
        } forType:@"application/json"];
    }
    
    [op addCompletionHandler:success errorHandler:failure];
    
    [m_engine enqueueOperation:op];
}

/*
//############################################################# User define methods ############################################################

//------------------------------------- User -------------------------------------
-(void)Login:(NSString*)email password:(NSString*)password success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/users/login", HostAddress];
    [self AsyncProcess:POST parameters:@{@"email" : email, @"password" : password, @"os" : @"iOS"} success:success failure:failure isJSON:NO];
}

-(void)CreateBP:(NSString*)secretKey userInfo:(NSDictionary*)userInfo success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/userapi/createbp", HostAddress];
    [self AsyncProcess:POST parameters:nil success:success failure:failure isJSON:YES];
}

-(void)CreateUser:(NSDictionary*)userObj sfdcAccount:(NSString*)sfdcAccountId success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/userapi/create", HostAddress];
    [self AsyncProcess:POST parameters:@{@"user" : userObj, @"sfdcAccountId" : sfdcAccountId} success:success failure:failure isJSON:YES];
}

-(void)DeleteUser:(NSString*)userId success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/userapi/%@", HostAddress, userId];
    [self AsyncProcess:DELETE parameters:nil success:success failure:failure isJSON:NO];
}

-(void)GetMembers:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/users/accounts", HostAddress];
    [self AsyncProcess:GET parameters:nil success:success failure:failure isJSON:NO];
}

-(void)GetAllAdmins:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/userapi/admin", HostAddress];
    [self AsyncProcess:GET parameters:nil success:success failure:failure isJSON:NO];
}

-(void)GetAppConfiguration:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/userapi/applications", HostAddress];
    [self AsyncProcess:GET parameters:nil success:success failure:failure isJSON:NO];
}

-(void)GetEnphaseAuthURL:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/enphase/authurl", HostAddress];
    [self AsyncProcess:GET parameters:nil success:success failure:failure isJSON:NO];
}

-(void)GetEnphaseInventory:(NSString*)systemID success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/enphase/inventory/%@", HostAddress, systemID];
    [self AsyncProcess:GET parameters:nil success:success failure:failure isJSON:NO];
}

-(void)GetEnphaseSystems:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/enphase/systems", HostAddress];
    [self AsyncProcess:GET parameters:nil success:success failure:failure isJSON:NO];
}

-(void)GetUserInfoById:(NSString*)userId success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/userapi/id/%@", HostAddress, userId];
    [self AsyncProcess:GET parameters:nil success:success failure:failure isJSON:NO];
}

-(void)SearchUsers:(NSString*)searchKey success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/userapi/%@", HostAddress, searchKey];
    [self AsyncProcess:GET parameters:nil success:success failure:failure isJSON:NO];
}

-(void)UpdateUserInfo:(NSDictionary*)param success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/userapi/edit", HostAddress];
    [self AsyncProcess:POST parameters:@{@"user" : param} success:success failure:failure isJSON:YES];
}

//--------------------------------------------------------------------------------

//------------------------------------- Tags -------------------------------------
-(void)AddAccessibleTag:(NSString*)userId object:(NSDictionary*)accessibleTagObj success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/userapi/tags/%@", HostAddress, userId];
    [self AsyncProcess:POST parameters:accessibleTagObj success:success failure:failure isJSON:YES];
}

-(void)CheckTagDeletable:(NSString*)tagId success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/api/tag/deletable/%@", HostAddress, tagId];
    [self AsyncProcess:GET parameters:nil success:success failure:failure isJSON:NO];
}

-(void)CreateTag:(NSDictionary*)tagObj success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/api/tag", HostAddress];
    [self AsyncProcess:POST parameters:tagObj success:success failure:failure isJSON:YES];
}

-(void)CreateTagRule:(NSDictionary*)ruleObj success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/api/tagrule", HostAddress];
    [self AsyncProcess:POST parameters:ruleObj success:success failure:failure isJSON:YES];
}

-(void)DeleteTag:(NSString*)tagId success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/api/tag/%@", HostAddress, tagId];
    [self AsyncProcess:DELETE parameters:nil success:success failure:failure isJSON:NO];
}

-(void)DeleteTagRule:(NSString*)ruleId success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/api/tagrule/%@", HostAddress, ruleId];
    [self AsyncProcess:DELETE parameters:nil success:success failure:failure isJSON:NO];
}

-(void)EditTag:(NSDictionary*)tagObj tagId:(NSString*)tagId success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/api/tag/%@", HostAddress, tagId];
    [self AsyncProcess:PUT parameters:tagObj success:success failure:failure isJSON:YES];
}

-(void)EditTagRule:(NSDictionary*)ruleObj ruleId:(NSString*)ruleId success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/api/tagrule/%@", HostAddress, ruleId];
    [self AsyncProcess:PUT parameters:ruleObj success:success failure:failure isJSON:YES];
}

-(void)GetTagRules:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/api/tagrule", HostAddress];
    [self AsyncProcess:GET parameters:nil success:success failure:failure isJSON:NO];
}

-(void)GetTagById:(NSString*)tagId success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/api/tag/%@", HostAddress, tagId];
    [self AsyncProcess:GET parameters:nil success:success failure:failure isJSON:NO];
}

-(void)GetUserTags:(NSString*)userId success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/users/%@/tags", HostAddress, userId];
    [self AsyncProcess:GET parameters:nil success:success failure:failure isJSON:NO];
}

-(void)RemoveAccessibleTag:(NSString*)accessibleTagId userID:(NSString*)userId success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/userapi/tags/%@/%@", HostAddress, accessibleTagId, userId];
    [self AsyncProcess:DELETE parameters:nil success:success failure:failure isJSON:NO];
}
//--------------------------------------------------------------------------------

//------------------------------------- Assets -----------------------------------
-(void)UploadUserPicture:(NSData*)fileData success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/assets/userprofile", HostAddress];
    MKNetworkOperation* op = [[MKNetworkOperation alloc] initWithURLString:m_apiURL params:nil httpMethod:@"POST"];
    [op setHeader:@"authorization" withValue:[SharedMembers sharedInstance].Token];
    NSString* filePath = [NSString stringWithFormat:@"%@/%@.png", [SharedMembers GetSavePath:@"upload"], [[NSUUID UUID] UUIDString]];
    [fileData writeToFile:filePath atomically:YES];
    [op addFile:filePath forKey:@"assetsFile"];
    [op addCompletionHandler:success errorHandler:failure];
    [m_engine enqueueOperation:op];
}
//--------------------------------------------------------------------------------

//------------------------------------- Accounts ---------------------------------
-(void)GetAllAccounts:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/accounts", HostAddress];
    [self AsyncProcess:GET parameters:nil success:success failure:false isJSON:NO];
}

-(void)CreateAccount:(NSDictionary*)account member:(NSDictionary*)member success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/accountapi/create", HostAddress];
    [self AsyncProcess:POST parameters:@{@"account" : account, @"user" : member} success:success failure:false isJSON:YES];
}

-(void)CreateAccountWithSF:(NSDictionary*)account member:(NSDictionary*)member success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/accountapi/createwithsf", HostAddress];
    [self AsyncProcess:POST parameters:@{@"account" : account, @"user" : member} success:success failure:false isJSON:YES];
}

-(void)UpdateAccount:(NSDictionary*)account success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/accountapi/edit", HostAddress];
    [self AsyncProcess:POST parameters:@{@"account" : account} success:success failure:failure isJSON:YES];
}

-(void)VerifyAccountCName:(NSString*)cName success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/accountapi/verifycname/%@", HostAddress, cName];
    [self AsyncProcess:GET parameters:nil success:success failure:false isJSON:NO];
}

-(void)DeleteAccount:(NSString*)accountId success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/accountapi/del/%@", HostAddress, accountId];
    [self AsyncProcess:DELETE parameters:nil success:success failure:false isJSON:NO];
}

//--------------------------------------------------------------------------------

//------------------------------------- Others -----------------------------------
-(void)GetDevices:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/collection/nodes", HostAddress];
    [self AsyncProcess:GET parameters:nil success:success failure:false isJSON:NO];
}

-(void)GetManufacturers:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/collection/scopes", HostAddress];
    [self AsyncProcess:GET parameters:nil success:success failure:false isJSON:NO];
}

-(void)GetSFDCAccounts:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/salesforce/accounts", HostAddress];
    [self AsyncProcess:GET parameters:nil success:success failure:false isJSON:NO];
}

-(void)GetUtilityProviders:(NSString*)findNameMask success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/salesforce/utilityproviders/%@", HostAddress, findNameMask];
    [self AsyncProcess:GET parameters:nil success:success failure:false isJSON:NO];
}

//------------------------------------- Dashboard --------------------------------

-(void)GetAllDashboards:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/analyze/dashboards", HostAddress];

    [self AsyncProcess:GET parameters:nil success:success failure:failure isJSON:NO];
}

-(void)CreateDashboard:(NSDictionary *)dashboardObj success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/analyze/dashboards", HostAddress];

    [self AsyncProcess:POST parameters:dashboardObj success:success failure:failure isJSON:YES];
}

-(void)UpdateDashboard:(NSString *)dashboardId param:(NSDictionary *)dashboardObj success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/analyze/dashboards/%@", HostAddress, dashboardId];
    
    [self AsyncProcess:PUT parameters:dashboardObj success:success failure:failure isJSON:YES];
}

-(void)DeleteDashboard:(NSString *)dashboardId success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/analyze/dashboards/%@", HostAddress, dashboardId];

    [self AsyncProcess:DELETE parameters:nil success:success failure:failure isJSON:NO];
}

-(void)GetDashboard:(NSString *)dashboardId success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/analyze/dashboards/%@", HostAddress, dashboardId];

    [self AsyncProcess:GET parameters:nil success:success failure:failure isJSON:NO];
}

-(void)GetMetricsInDashboard:(NSString *)dashboardId success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/analyze/dashboards/%@/metrics", HostAddress, dashboardId];

    [self AsyncProcess:GET parameters:nil success:success failure:failure isJSON:NO];
}

-(void)GetAllSegmentsInDashboard:(NSString *)dashboardId success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/analyze/dashboards/%@/tags/segments", HostAddress, dashboardId];
    [self AsyncProcess:GET parameters:nil success:success failure:failure isJSON:NO];
}

-(void)DeleteSegmentInDashboard:(NSString *)dashboardId segment:(NSString *)segment success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/analyze/dashboards/%@/tags/segments/%@", HostAddress, dashboardId, segment];
    [self AsyncProcess:DELETE parameters:nil success:success failure:failure isJSON:NO];
}

-(void)AddNewSegmentInDashboard:(NSString *)dashboardId param:(NSArray *)param success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/analyze/dashboards/%@/tags/segments", HostAddress, dashboardId];
    [self AsyncProcess:POST parameters:param success:success failure:failure isJSON:YES];
}

-(void)UpdateSegmentInDashboard:(NSString *)dashboardId param:(NSArray *)param success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/analyze/dashboards/%@/tags/segments", HostAddress, dashboardId];
    [self AsyncProcess:PUT parameters:param success:success failure:failure isJSON:YES];
}

-(void)AddNewWidget:(NSString *)dashboardId param:(NSDictionary *)param success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/analyze/dashboards/%@/widgets", HostAddress, dashboardId];
    [self AsyncProcess:POST parameters:param success:success failure:failure isJSON:YES];
}

-(void)UpdateNewWidget:(NSString *)dashboardId widgetId:(NSString *)widgetId param:(NSDictionary *)param success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/analyze/dashboards/%@/widgets/%@", HostAddress, dashboardId, widgetId];
    [self AsyncProcess:PUT parameters:param success:success failure:failure isJSON:YES];
}

-(void)DeleteWidget:(NSString *)dashboardId widget:(NSString *)widgetId success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/analyze/dashboards/%@/widgets/%@", HostAddress, dashboardId, widgetId];
    [self AsyncProcess:DELETE parameters:nil success:success failure:failure isJSON:NO];
}

-(void)GetDashboardWidgetDatas:(NSString *)dashboardId success:(SuccessBlock)success failure:(ErrorBlock)failure
{
    m_apiURL = [NSString stringWithFormat:@"%@/analyze/dashboards/%@/widgets", HostAddress, dashboardId];
    [self AsyncProcess:GET parameters:nil success:success failure:failure isJSON:NO];
}

//--------------------------------------------------------------------------------

//##############################################################################################################################################
*/
@end
