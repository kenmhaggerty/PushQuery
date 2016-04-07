//
//  PQSurveysTableViewController.m
//  PushQuery
//
//  Created by Ken M. Haggerty on 3/16/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

#pragma mark - // NOTES (Private) //

#pragma mark - // IMPORTS (Private) //

#import "PQSurveysTableViewController.h"
#import "AKDebugger.h"
#import "AKGenerics.h"

#import "PQLoginManager.h"
#import "PQDataManager.h"
#import "PQSurveyProtocols.h"
#import "PQPrivateInfo.h"

#import "PQSurveyUIProtocol.h"
#import "UIViewController+Email.h"
@import SafariServices;

#pragma mark - // DEFINITIONS (Private) //

NSString * const PQContactUsEmail = @"kenmhaggerty@gmail.com";
NSString * const PQContactUsSubject = @"PushQuery: Customer Email";

NSString * const REUSE_IDENTIFIER = @"surveyCell";
NSString * const SEGUE_SURVEY = @"segueSurvey";
NSString * const SEGUE_LOGIN = @"segueLogin";

@interface PQSurveysTableViewController ()
@property (nonatomic, strong) IBOutlet UIBarButtonItem *addButton;
@property (nonatomic, strong) NSMutableOrderedSet <id <PQSurvey>> *surveys;
@property (nonatomic, strong) UIAlertController *alertSettings;
@property (nonatomic, strong) UIAlertController *alertUpdateEmail;
@property (nonatomic, strong) UIAlertController *alertEmailUpdated;
@property (nonatomic, strong) UIAlertController *alertUpdatePassword;
@property (nonatomic, strong) UIAlertController *alertMismatchedPasswords;
@property (nonatomic, strong) UIAlertController *alertInvalidPassword;
@property (nonatomic, strong) UIAlertController *alertPasswordUpdated;

// ACTIONS //

- (IBAction)settings:(id)sender;
- (IBAction)newSurvey:(id)sender;

// OBSERVERS //

- (void)addObserversToLoginManager;
- (void)removeObserversFromLoginManager;
- (void)addObserversToSurvey:(id <PQSurvey>)survey;
- (void)removeObserversFromSurvey:(id <PQSurvey>)survey;

// RESPONDERS //

- (void)currentUserDidChange:(NSNotification *)notification;
- (void)emailDidChange:(NSNotification *)notification;
- (void)surveyDidChange:(NSNotification *)notification;

// OTHER //

+ (NSString *)stringForDate:(NSDate *)date;

@end

@implementation PQSurveysTableViewController

#pragma mark - // SETTERS AND GETTERS //

- (void)setSurveys:(NSMutableOrderedSet <id <PQSurvey>> *)surveys {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetter tags:nil message:nil];
    
    if ([AKGenerics object:surveys isEqualToObject:_surveys]) {
        return;
    }
    
    for (id <PQSurvey> survey in _surveys) {
        [self removeObserversFromSurvey:survey];
    }
    
    _surveys = surveys;
    
    for (id <PQSurvey> survey in surveys) {
        [self addObserversToSurvey:survey];
    }
    
#warning TO DO – Loading indicator if surveys is nil
    [self.tableView reloadData];
}

- (UIAlertController *)alertSettings {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_UI] message:nil];
    
    if (_alertSettings) {
        return _alertSettings;
    }
    
    _alertSettings = [UIAlertController alertControllerWithTitle:@"Settings" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [_alertSettings addAction:[UIAlertAction actionWithTitle:@"Sign out" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [PQLoginManager logout];
    }]];
    [_alertSettings addAction:[UIAlertAction actionWithTitle:@"Update email" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self presentViewController:self.alertUpdateEmail animated:YES completion:nil];
    }]];
    [_alertSettings addAction:[UIAlertAction actionWithTitle:@"Change password" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self presentViewController:self.alertUpdatePassword animated:YES completion:nil];
    }]];
    [_alertSettings addAction:[UIAlertAction actionWithTitle:@"Contact Us" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        id <PQUser> currentUser = [PQLoginManager currentUser];
        NSString *suffix = @"";
        if (currentUser && currentUser.username) {
            suffix = [NSString stringWithFormat:@" from %@", currentUser.username];
        }
        NSString *subject = [NSString stringWithFormat:@"%@%@", PQContactUsSubject, suffix];
        NSString *body = @"<p>Please enter your feedback below and we'll get back to you within 24 hours:</p>";
        
        BOOL success = [self emailInCurrentAppWithSubject:subject body:body attachments:nil to:@[PQContactUsEmail] cc:nil bcc:nil completionBlock:nil];
        if (!success) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Need Support?" message:@"Email me at kenmhaggerty@gmail.com." preferredStyle:UIAlertControllerStyleAlert actions:@[@"Send Email"] dismissalText:@"Cancel" completion:^(UIAlertAction *action) {
                
                NSURLComponents *mailTo = [NSURLComponents componentsWithString:[NSString stringWithFormat:@"mailto:%@", PQContactUsEmail]];
                NSURLQueryItem *subjectQuery = [NSURLQueryItem queryItemWithName:@"subject" value:subject];
                NSURLQueryItem *bodyQuery = [NSURLQueryItem queryItemWithName:@"body" value:body];
                mailTo.queryItems = @[subjectQuery, bodyQuery];
                
                [[UIApplication sharedApplication] openURL:mailTo.URL];
            }];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }]];
    [_alertSettings addAction:[UIAlertAction actionWithTitle:@"Privacy Policy" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:@"http://kenmhaggerty.com/pushquery/privacy/"]];
        safariViewController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:safariViewController animated:YES completion:nil];
    }]];
    [_alertSettings addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    return _alertSettings;
}

- (UIAlertController *)alertUpdateEmail {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_UI] message:nil];
    
    if (_alertUpdateEmail) {
        return _alertUpdateEmail;
    }
    
    _alertUpdateEmail = [UIAlertController alertControllerWithTitle:@"Update Email" message:@"Please enter a valid email and your current password. Your new email will also be used for signing in to your account." preferredStyle:UIAlertControllerStyleAlert actions:@[@"Update"] dismissalText:@"Cancel" completion:^(UIAlertAction *action) {
        
        NSString *email = _alertUpdateEmail.textFields[0].text;
        NSString *password = _alertUpdateEmail.textFields[1].text;
        
        [PQLoginManager updateEmail:email password:password withSuccess:^{
            [self presentViewController:self.alertEmailUpdated animated:YES completion:[AKGenerics clearTextFields:_alertUpdateEmail]];
            
        } failure:^(NSError *error) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Couldn't Update Email" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert actions:nil dismissalText:@"Cancel" completion:nil];
            [self presentViewController:alertController animated:YES completion:[AKGenerics clearTextFields:_alertUpdateEmail]];
        }];
    }];
    [_alertUpdateEmail addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"new email";
    }];
    [_alertUpdateEmail addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"password";
        textField.secureTextEntry = YES;
    }];
    return _alertUpdateEmail;
}

- (UIAlertController *)alertEmailUpdated {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_UI] message:nil];
    
    if (_alertEmailUpdated) {
        return _alertEmailUpdated;
    }
    
    _alertEmailUpdated = [UIAlertController alertControllerWithTitle:@"Email Updated" message:@"Your email was successfully updated." preferredStyle:UIAlertControllerStyleAlert actions:nil dismissalText:@"Dismiss" completion:nil];
    return _alertEmailUpdated;
}

- (UIAlertController *)alertUpdatePassword {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_UI] message:nil];
    
    if (_alertUpdatePassword) {
        return _alertUpdatePassword;
    }
    
    _alertUpdatePassword = [UIAlertController alertControllerWithTitle:@"Update Password" message:[PQPrivateInfo passwordRequirements] preferredStyle:UIAlertControllerStyleAlert actions:@[@"Update"] dismissalText:@"Cancel" completion:^(UIAlertAction *action) {
        
        NSString *oldPassword = _alertUpdatePassword.textFields[0].text;
        NSString *newPassword = _alertUpdatePassword.textFields[1].text;
        NSString *newPasswordConfirm = _alertUpdatePassword.textFields[2].text;
        
        if (![AKGenerics object:newPassword isEqualToObject:newPasswordConfirm]) {
            [self presentViewController:self.alertMismatchedPasswords animated:YES completion:[AKGenerics clearTextFields:_alertUpdatePassword]];
            return;
        }
        
        if (![PQPrivateInfo validPassword:newPassword]) {
            [self presentViewController:self.alertInvalidPassword animated:YES completion:[AKGenerics clearTextFields:_alertUpdatePassword]];
            return;
        }
        
        [PQLoginManager updatePassword:oldPassword toPassword:newPassword withSuccess:^{
            [self presentViewController:self.alertPasswordUpdated animated:YES completion:[AKGenerics clearTextFields:_alertUpdatePassword]];
            
        } failure:^(NSError *error) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Couldn't Update Password" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert actions:nil dismissalText:@"Dismiss" completion:nil];
            [self presentViewController:alertController animated:YES completion:[AKGenerics clearTextFields:_alertUpdatePassword]];
        }];
    }];
    [_alertUpdatePassword addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"enter current password";
        textField.secureTextEntry = YES;
    }];
    [_alertUpdatePassword addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"enter new password";
        textField.secureTextEntry = YES;
    }];
    [_alertUpdatePassword addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"confirm new password";
        textField.secureTextEntry = YES;
    }];
    return _alertUpdatePassword;
}

- (UIAlertController *)alertMismatchedPasswords {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_UI] message:nil];
    
    if (_alertMismatchedPasswords) {
        return _alertMismatchedPasswords;
    }
    
    _alertMismatchedPasswords = [UIAlertController alertControllerWithTitle:@"Couldn't Update Password" message:@"Your password confirmation did not match your new password." preferredStyle:UIAlertControllerStyleAlert actions:@[@"Retry"] dismissalText:@"Cancel" completion:^(UIAlertAction *action) {
        [self presentViewController:_alertUpdatePassword animated:YES completion:nil];
    }];
    return _alertMismatchedPasswords;
}

- (UIAlertController *)alertInvalidPassword {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_UI] message:nil];
    
    if (_alertInvalidPassword) {
        return _alertInvalidPassword;
    }
    
    _alertInvalidPassword = [UIAlertController alertControllerWithTitle:@"Couldn't Update Password" message:@"Your new password did not meet requirements." preferredStyle:UIAlertControllerStyleAlert actions:@[@"Retry"] dismissalText:@"Cancel" completion:^(UIAlertAction *action) {
        [self presentViewController:_alertUpdatePassword animated:YES completion:nil];
    }];
    return _alertInvalidPassword;
}

- (UIAlertController *)alertPasswordUpdated {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_UI] message:nil];
    
    if (_alertPasswordUpdated) {
        return _alertPasswordUpdated;
    }
    
    _alertPasswordUpdated = [UIAlertController alertControllerWithTitle:@"Password Updated" message:@"Your password was successfully updated." preferredStyle:UIAlertControllerStyleAlert actions:nil dismissalText:@"Dismiss" completion:nil];
    return _alertPasswordUpdated;
}

#pragma mark - // INITS AND LOADS //

- (void)dealloc {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_UI] message:nil];
    
    [self teardown];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_UI] message:nil];
    
    self  = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_UI] message:nil];
    
    [super awakeFromNib];
    
    [self setup];
}

- (void)viewDidLoad {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_UI] message:nil];
    
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_UI] message:nil];
    
    [super viewDidAppear:animated];
    
    if (![PQLoginManager currentUser]) {
        [self performSegueWithIdentifier:SEGUE_LOGIN sender:self];
    }
}

#pragma mark - // PUBLIC METHODS //

#pragma mark - // CATEGORY METHODS //

#pragma mark - // DELEGATED METHODS (UITableViewDataSource) //

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_UI] message:nil];
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_UI] message:nil];
    
    return (self.surveys ? self.surveys.count : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_UI] message:nil];
    
    UITableViewCell *cell = [AKGenerics cellWithReuseIdentifier:REUSE_IDENTIFIER class:[UITableViewCell class] style:UITableViewCellStyleDefault tableView:tableView atIndexPath:indexPath fromStoryboard:YES];
    id <PQSurvey> survey = self.surveys[indexPath.row];
    cell.textLabel.text = survey.name ?: PQSurveyNamePlaceholder;
    cell.textLabel.textColor = (survey.name ? [UIColor blackColor] : [UIColor lightGrayColor]);
    cell.detailTextLabel.text = [PQSurveysTableViewController stringForDate:survey.editedAt];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_UI] message:nil];
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        id <PQSurvey_Editable> survey = (id <PQSurvey_Editable>)self.surveys[indexPath.row];
        [PQDataManager deleteSurvey:survey];
        [PQDataManager save];
    }
}

#pragma mark - // DELEGATED METHODS (UITableViewDelegate) //

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeAction tags:@[AKD_UI] message:nil];
    
    id survey = self.surveys[indexPath.row];
    [self performSegueWithIdentifier:SEGUE_SURVEY sender:survey];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - // OVERWRITTEN METHODS //

- (void)setup {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_UI] message:nil];
    
    [super setup];
    
    _surveys = [NSMutableOrderedSet orderedSet];
    
    [self addObserversToLoginManager];
}

- (void)teardown {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_UI] message:nil];
    
    [self removeObserversFromLoginManager];
    
    [super teardown];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_UI] message:nil];
    
    if (![sender conformsToProtocol:@protocol(PQSurvey)]) {
        return;
    }
    
    id <PQSurvey> survey = (id <PQSurvey>)sender;
    
    if ([segue.destinationViewController conformsToProtocol:@protocol(PQSurveyUI)]) {
        ((UIViewController <PQSurveyUI> *)segue.destinationViewController).survey = survey;
    }
    [segue.destinationViewController performBlockOnChildViewControllers:^(UIViewController *childViewController) {
        if ([childViewController conformsToProtocol:@protocol(PQSurveyUI)]) {
            ((UIViewController <PQSurveyUI> *)childViewController).survey = survey;
        }
    }];
}

#pragma mark - // PRIVATE METHODS (Actions) //

- (IBAction)settings:(id)sender {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeAction tags:@[AKD_UI] message:nil];
    
    id <PQUser_Editable> currentUser = [PQLoginManager currentUser];
    self.alertSettings.message = currentUser.email;
    [self presentViewController:self.alertSettings animated:YES completion:nil];
}

- (IBAction)newSurvey:(id)sender {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeAction tags:@[AKD_UI] message:nil];
    
    id <PQSurvey> survey = [PQDataManager survey];
    [self addObserversToSurvey:survey];
    [self.surveys insertObject:survey atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [CATransaction begin];
    [self.tableView beginUpdates];
    [CATransaction setCompletionBlock:^{
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
    [self.tableView endUpdates];
    [CATransaction commit];
//    [self performSegueWithIdentifier:SEGUE_SURVEY sender:survey];
}

#pragma mark - // PRIVATE METHODS (Observers) //

- (void)addObserversToLoginManager {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_NOTIFICATION_CENTER] message:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentUserDidChange:) name:PQLoginManagerCurrentUserDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(emailDidChange:) name:PQLoginManagerEmailDidChangeNotification object:nil];
}

- (void)removeObserversFromLoginManager {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_NOTIFICATION_CENTER] message:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PQLoginManagerCurrentUserDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PQLoginManagerEmailDidChangeNotification object:nil];
}

- (void)addObserversToSurvey:(id <PQSurvey>)survey {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_NOTIFICATION_CENTER] message:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(surveyDidChange:) name:PQSurveyNameDidChangeNotification object:survey];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(surveyDidChange:) name:PQSurveyEditedAtDidChangeNotification object:survey];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(surveyWillBeDeleted:) name:PQSurveyWillBeDeletedNotification object:survey];
}

- (void)removeObserversFromSurvey:(id <PQSurvey>)survey {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_NOTIFICATION_CENTER] message:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PQSurveyNameDidChangeNotification object:survey];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PQSurveyEditedAtDidChangeNotification object:survey];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PQSurveyWillBeDeletedNotification object:survey];
}

#pragma mark - // PRIVATE METHODS (Responders) //

- (void)currentUserDidChange:(NSNotification *)notification {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_NOTIFICATION_CENTER, AKD_ACCOUNTS] message:nil];
    
    id <PQUser> currentUser = notification.userInfo[NOTIFICATION_OBJECT_KEY];
    if (currentUser) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSMutableOrderedSet *surveys = [NSMutableOrderedSet orderedSetWithSet:[PQDataManager surveysAuthoredByUser:currentUser]];
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(editedAt)) ascending:NO];
            [surveys sortUsingDescriptors:@[sortDescriptor]];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.surveys = surveys;
            });
        });
    }
    else {
        self.surveys = nil;
        [self performSegueWithIdentifier:SEGUE_LOGIN sender:self];
    }
}

- (void)emailDidChange:(NSNotification *)notification {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_NOTIFICATION_CENTER] message:nil];
    
    NSString *email = notification.userInfo[NOTIFICATION_OBJECT_KEY];
    
    self.alertSettings.message = email;
}

- (void)surveyDidChange:(NSNotification *)notification {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_NOTIFICATION_CENTER, AKD_DATA, AKD_UI] message:nil];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.surveys indexOfObject:notification.object] inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)surveyWillBeDeleted:(NSNotification *)notification {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_NOTIFICATION_CENTER, AKD_DATA, AKD_UI] message:nil];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.surveys indexOfObject:notification.object] inSection:0];
    [self.surveys removeObject:notification.object];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - // PRIVATE METHODS (Other) //

+ (NSString *)stringForDate:(NSDate *)date {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_UI] message:nil];
    
    NSString *dateString = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
    NSString *timeString = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle];
    return [NSString stringWithFormat:@"%@ at %@", dateString, timeString];
}

@end