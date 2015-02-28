//
//  FaqViewController.m
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "FaqViewController.h"

#import "MyBentoViewController.h"

#import "MyAlertView.h"

#import "JGProgressHUD.h"

#import "AppStrings.h"
#import "WebManager.h"
#import "DataManager.h"

#import <MessageUI/MessageUI.h>

@interface FaqViewController () <MFMailComposeViewControllerDelegate, MyAlertViewDelegate>

@property (nonatomic, assign) IBOutlet UILabel *lblTitle;

@property (nonatomic, assign) IBOutlet UIButton *btnLogout;

@property (nonatomic, assign) IBOutlet UILabel *lblDescription;
@property (nonatomic, assign) IBOutlet UITextView *tvDescription;

@property (nonatomic, assign) IBOutlet UIWebView *webView;
@property (nonatomic, assign) IBOutlet UIActivityIndicatorView *viewActivity;

@property (nonatomic, assign) IBOutlet UIButton *btnFinishing;

@end

@implementation FaqViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapDescription:)];
    [self.tvDescription addGestureRecognizer:tapGesture];
    tapGesture = nil;
    
    self.tvDescription.linkTextAttributes = @{NSUnderlineStyleAttributeName:[NSNumber numberWithInt:NSUnderlineStyleSingle]};
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self initContent];
    
    NSDictionary *curUserInfo = [[DataManager shareDataManager] getUserInfo];
    if (curUserInfo != nil)
        self.btnLogout.hidden = NO;
    else
        self.btnLogout.hidden = YES;
}

- (void) initContent
{
    NSURL *urlNavigate = nil;
    
    switch (self.contentType) {
        case CONTENT_PRIVACY:
        {
            self.lblTitle.text = [[AppStrings sharedInstance] getString:POLICY_TITLE];
            self.lblDescription.text = [[AppStrings sharedInstance] getString:POLICY_CONTACT_US];
            self.tvDescription.text = [[AppStrings sharedInstance] getString:POLICY_CONTACT_US];
            [self.btnFinishing setTitle:[[AppStrings sharedInstance] getString:POLICY_BUTTON_FINISH] forState:UIControlStateNormal];
            urlNavigate = [[AppStrings sharedInstance] getURL:POLICY_LINK_BODY];
        }
            break;
            
        case CONTENT_TERMS:
        {
            self.lblTitle.text = [[AppStrings sharedInstance] getString:TERMS_TITLE];
            self.lblDescription.text = [[AppStrings sharedInstance] getString:TERMS_CONTACT_US];
            self.tvDescription.text = [[AppStrings sharedInstance] getString:TERMS_CONTACT_US];
            [self.btnFinishing setTitle:[[AppStrings sharedInstance] getString:TERMS_BUTTON_FINISH] forState:UIControlStateNormal];
            urlNavigate = [[AppStrings sharedInstance] getURL:TERMS_LINK_BODY];
        }
            break;
            
        case CONTENT_FAQ:
        {
            self.lblTitle.text = [[AppStrings sharedInstance] getString:FAQ_TITLE];
            self.lblDescription.text = [[AppStrings sharedInstance] getString:FAQ_CONTACT_US];
            self.tvDescription.text = [[AppStrings sharedInstance] getString:FAQ_CONTACT_US];
            [self.btnFinishing setTitle:[[AppStrings sharedInstance] getString:FAQ_BUTTON_FINISH] forState:UIControlStateNormal];
            urlNavigate = [[AppStrings sharedInstance] getURL:FAQ_LINK_BODY];
        }
            break;
            
        default:
            break;
    }
    
    if (self.tvDescription.text.length > 0)
    {
        NSString *strDesc = [self.tvDescription.text lowercaseString];
        NSRange range = [strDesc rangeOfString:@"email"];
        if (range.length == 0)
            range = [strDesc rangeOfString:@"e-mail"];
        
        if (range.length > 0)
        {
            NSMutableAttributedString *attrString = [self.tvDescription.attributedText mutableCopy];
            [attrString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:range];
            self.tvDescription.attributedText = attrString;
        }
    }

    if (urlNavigate != nil)
    {
        NSURLRequest *requestObj = [NSURLRequest requestWithURL:urlNavigate];
        [self.webView loadRequest:requestObj];
        
        self.viewActivity.hidden = NO;
        [self.viewActivity startAnimating];
    }
}

- (IBAction)onBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onLogout:(id)sender
{
    MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Confirmation" message:@"Are you sure you want to log out?" delegate:self cancelButtonTitle:@"No" otherButtonTitle:@"Yes"];
    alertView.tag = 1;
    [alertView showInView:self.view];
    alertView = nil;
}

- (IBAction)onFinishBuildingMyBento:(id)sender
{
//    [self gotoAddAnotherBentoScreen];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) gotoAddAnotherBentoScreen
{
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    for (UIViewController *vc in viewControllers) {
        
        if ([vc isKindOfClass:[MyBentoViewController class]])
        {
            [self.navigationController popToViewController:vc animated:YES];
            
            return;
        }
    }
    
    [self performSegueWithIdentifier:@"AddAnotherBento" sender:nil];
}

- (void)onSendMail
{
    if (![MFMailComposeViewController canSendMail])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Please set an E-mail account and try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
        [alertView show];
        alertView = nil;
        return;
    }
    
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    
    NSString *strContact = [[AppStrings sharedInstance] getContactMail];
    [picker setToRecipients:@[strContact]];
    
    NSString* strSubject = @"";
    [picker setSubject:strSubject];
    
    picker.navigationBar.barStyle = UIBarStyleDefault;
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void) onTapDescription:(UITapGestureRecognizer *)recognizer
{
    NSRange linkRange;
    {
        NSError *error = nil;
        NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypePhoneNumber error:&error];
        
        NSString *strDesc = self.tvDescription.text;
        NSArray *links = [detector matchesInString:strDesc options:0 range:NSMakeRange(0, [strDesc length])];
        
        if ([links count] > 0)
            linkRange = ((NSTextCheckingResult *)[links lastObject]).range;
        else
            [self onSendMail];
    }
    
    NSUInteger characterIndex;
    {
        UITextView *textView = (UITextView *)recognizer.view;
        
        // Location of the tap in text-container coordinates
        NSLayoutManager *layoutManager = textView.layoutManager;
        CGPoint location = [recognizer locationInView:textView];
        location.x -= textView.textContainerInset.left;
        location.y -= textView.textContainerInset.top;
        
        // Find the character that's been tapped on
        characterIndex = [layoutManager characterIndexForPoint:location
                                               inTextContainer:textView.textContainer
                      fractionOfDistanceBetweenInsertionPoints:NULL];
        
        if (linkRange.location <= characterIndex && characterIndex <= linkRange.location + linkRange.length)
            return;
    }
    
    [self onSendMail];
}

#pragma mark UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
/*
     NSCharacterSet *charSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789-+()"] invertedSet];
     NSString *cleanedString = [[self.tvPhone.text componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
     NSURL* callURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", cleanedString]];
 */
    
//    if ([[UIApplication sharedApplication] canOpenURL:URL])
//    {
//        return [[UIApplication sharedApplication] openURL:URL];
//    }
    
    return [[UIApplication sharedApplication] canOpenURL:URL];
}

#pragma mark UIWebViewDelegate

- (void)hideActivityView
{
    if (!self.viewActivity.hidden)
    {
        [self.viewActivity stopAnimating];
        self.viewActivity.hidden = YES;
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self hideActivityView];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self hideActivityView];
    
    MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Error" message:error.description delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
    [alertView showInView:self.view];
    alertView = nil;
}

#pragma mark MFMailControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    // Notifies users about errors associated with the interface
    switch (result)
    {
        case MFMailComposeResultCancelled:
            break;
        case MFMailComposeResultSaved:
            break;
        case MFMailComposeResultSent:
            break;
        case MFMailComposeResultFailed:
            break;
            
        default:
        {
            MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Email" message:@"Sending Failed - Unknown Error :-("
                                                           delegate:self cancelButtonTitle:@"OK" otherButtonTitle: nil];
            alertView.tag = -1;
            [alertView showInView:self.view];
            alertView = nil;
        }
            
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark MyAlertViewDelegate

- (void)processLogout
{
    NSDictionary *curUserInfo = [[DataManager shareDataManager] getUserInfo];
    if (curUserInfo == nil)
        return;
    
    NSString *strAPIToken = [[DataManager shareDataManager] getAPIToken];
    if (strAPIToken == nil || strAPIToken.length == 0)
        return;

    WebManager *webManager = [[WebManager alloc] init];
    
    JGProgressHUD *loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Logging out...";
    [loadingHUD showInView:self.view];
    
    NSString *strRequest = [NSString stringWithFormat:@"%@/user/logout?api_token=%@", SERVER_URL, strAPIToken];
    [webManager AsyncProcess:strRequest method:GET parameters:nil success:^(MKNetworkOperation *networkOperation) {
        [loadingHUD dismiss];
        
        [[DataManager shareDataManager] setUserInfo:nil];
        [[DataManager shareDataManager] setCreditCard:nil];
        
        NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
        [pref setObject:nil forKey:@"apiName"];
        [pref setObject:nil forKey:@"loginRequest"];
        [pref synchronize];
        
        self.btnLogout.hidden = YES;
        
    } failure:^(MKNetworkOperation *errorOp, NSError *error) {
        [loadingHUD dismiss];
        
        NSString *strMessage = [[DataManager shareDataManager] getErrorMessage:errorOp.responseJSON];
        if (strMessage == nil)
            strMessage = error.localizedDescription;
        
        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Error" message:strMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
        [alertView showInView:self.view];
        alertView = nil;
        
    } isJSON:NO];
}

- (void)alertView:(MyAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1)
    {
        if (buttonIndex == 1)
            [self processLogout];
    }
}


@end
