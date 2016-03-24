//
//  AMLCoreDataController.m
//  AskMeLater
//
//  Created by Ken M. Haggerty on 3/4/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

#pragma mark - // NOTES (Private) //

#pragma mark - // IMPORTS (Private) //

#import "AMLCoreDataController.h"
#import "AKDebugger.h"
#import "AKGenerics.h"
#import <CoreData/CoreData.h>

#import "AMLUser.h"
#import "AMLSurvey.h"
#import "AMLQuestion.h"
#import "AMLChoice.h"
#import "AMLResponse.h"

#pragma mark - // DEFINITIONS (Private) //

@interface AMLCoreDataController ()
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

// GENERAL //

+ (instancetype)sharedController;
+ (NSManagedObjectContext *)managedObjectContext;
+ (NSURL *)applicationDocumentsDirectory;

// GETTERS //

+ (id <AMLUser>)getUserWithEmail:(NSString *)email;

@end

@implementation AMLCoreDataController

#pragma mark - // SETTERS AND GETTERS //

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSManagedObjectContext *)managedObjectContext {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_CORE_DATA] message:nil];
    
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
    if (!coordinator) {
        return nil;
    }
    
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _managedObjectContext.persistentStoreCoordinator = coordinator;
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_CORE_DATA] message:nil];
    
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"AskMeLater" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_CORE_DATA] message:nil];
    
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[AMLCoreDataController applicationDocumentsDirectory] URLByAppendingPathComponent:@"AskMeLater.sqlite"];
    NSError *error;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - // INITS AND LOADS //

#pragma mark - // PUBLIC METHODS (General) //

+ (void)save {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_CORE_DATA] message:nil];
    
    NSManagedObjectContext *managedObjectContext = [AMLCoreDataController managedObjectContext];
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - // PUBLIC METHODS (Initializers) //

+ (id <AMLUser>)userWithEmail:(NSString *)email {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_CORE_DATA] message:nil];
    
    id <AMLUser> user = [AMLCoreDataController getUserWithEmail:email];
    if (user) {
        return user;
    }
    
    return [AMLCoreDataController userWithUsername:nil email:email];
}

+ (id <AMLUser_Editable>)userWithUsername:(NSString *)username email:(NSString *)email {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeCreator tags:@[AKD_CORE_DATA] message:nil];
    
    NSManagedObjectContext *managedObjectContext = [AMLCoreDataController managedObjectContext];
    __block AMLUser *user;
    [managedObjectContext performBlockAndWait:^{
        user = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([AMLUser class]) inManagedObjectContext:managedObjectContext];
        user.email = email;
        user.createdAt = [NSDate date];
    }];
    return user;
}

+ (id <AMLSurvey_Editable>)surveyWithName:(NSString *)name author:(id <AMLUser>)author {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeCreator tags:@[AKD_CORE_DATA] message:nil];
    
    NSManagedObjectContext *managedObjectContext = [AMLCoreDataController managedObjectContext];
    __block AMLSurvey *survey;
    [managedObjectContext performBlockAndWait:^{
        survey = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([AMLSurvey class]) inManagedObjectContext:managedObjectContext];
        survey.name = name;
        survey.author = (AMLUser *)author;
        survey.createdAt = [NSDate date];
        survey.editedAt = survey.createdAt;
    }];
    return survey;
}

+ (id <AMLQuestion_Editable>)questionWithText:(NSString *)text choices:(NSOrderedSet <id <AMLChoice>> *)choices {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeCreator tags:@[AKD_CORE_DATA] message:nil];
    
    NSManagedObjectContext *managedObjectContext = [AMLCoreDataController managedObjectContext];
    __block AMLQuestion *question;
    [managedObjectContext performBlockAndWait:^{
        question = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([AMLQuestion class]) inManagedObjectContext:managedObjectContext];
        question.text = text;
        question.choices = (NSOrderedSet <AMLChoice *> *)choices;
    }];
    return question;
}

+ (id <AMLChoice_Editable>)choiceWithText:(NSString *)text {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeCreator tags:@[AKD_CORE_DATA] message:nil];
    
    NSManagedObjectContext *managedObjectContext = [AMLCoreDataController managedObjectContext];
    __block AMLChoice *choice;
    [managedObjectContext performBlockAndWait:^{
        choice = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([AMLChoice class]) inManagedObjectContext:managedObjectContext];
        choice.text = text;
    }];
    return choice;
}

+ (id <AMLResponse_Editable>)responseWithText:(NSString *)text user:(id<AMLUser>)user date:(NSDate *)date {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeCreator tags:@[AKD_CORE_DATA] message:nil];
    
    NSManagedObjectContext *managedObjectContext = [AMLCoreDataController managedObjectContext];
    __block AMLResponse *response;
    [managedObjectContext performBlockAndWait:^{
        response = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([AMLResponse class]) inManagedObjectContext:managedObjectContext];
        response.text = text;
        response.user = (AMLUser *)user;
        response.date = date;
    }];
    return response;
}

#pragma mark - // CATEGORY METHODS //

#pragma mark - // DELEGATED METHODS //

#pragma mark - // OVERWRITTEN METHODS //

#pragma mark - // PRIVATE METHODS (General) //

+ (instancetype)sharedController {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_CORE_DATA] message:nil];
    
    static AMLCoreDataController *_sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedController = [[AMLCoreDataController alloc] init];
    });
    return _sharedController;
}

+ (NSManagedObjectContext *)managedObjectContext {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_CORE_DATA] message:nil];
    
    return [AMLCoreDataController sharedController].managedObjectContext;
}

+ (NSURL *)applicationDocumentsDirectory {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_CORE_DATA] message:nil];
    
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.flatiron-school.learn.ios.AskMeLater" in the application's documents directory.
    
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - // PRIVATE METHODS (Getters) //

+ (id <AMLUser_Editable>)getUserWithEmail:(NSString *)email {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_CORE_DATA] message:nil];
    
    NSManagedObjectContext *managedObjectContext = [AMLCoreDataController managedObjectContext];
    __block NSArray *foundUsers;
    __block NSError *error;
    [managedObjectContext performBlockAndWait:^{
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:[NSEntityDescription entityForName:NSStringFromClass([AMLUser class]) inManagedObjectContext:managedObjectContext]];
        [request setPredicate:[NSPredicate predicateWithFormat:@"(%K == %@)", NSStringFromSelector(@selector(email)), email]];
        [request setSortDescriptors:[NSArray arrayWithObjects: [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(createdAt)) ascending:YES], nil]];
        foundUsers = [managedObjectContext executeFetchRequest:request error:&error];
    }];
    if (error)
    {
        [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeError methodType:AKMethodTypeGetter tags:@[AKD_CORE_DATA] message:[NSString stringWithFormat:@"%@, %@", error, error.userInfo]];
    }
    if (!foundUsers)
    {
        [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeNotice methodType:AKMethodTypeGetter tags:@[AKD_CORE_DATA] message:[NSString stringWithFormat:@"%@ is nil", stringFromVariable(foundUsers)]];
        return nil;
    }
    
    if (foundUsers.count > 1)
    {
        [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeNotice methodType:AKMethodTypeGetter tags:@[AKD_CORE_DATA] message:[NSString stringWithFormat:@"Found %lu %@ object(s) with %@ %@; returning first object", (unsigned long)foundUsers.count, NSStringFromClass([AMLUser class]), stringFromVariable(email), email]];
    }
    return [foundUsers firstObject];
}

@end
