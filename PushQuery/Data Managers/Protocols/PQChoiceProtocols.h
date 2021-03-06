//
//  PQChoiceProtocols.h
//  PushQuery
//
//  Created by Ken M. Haggerty on 3/16/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

#pragma mark - // NOTES //

#pragma mark - // IMPORTS //

#import <Foundation/Foundation.h>

#pragma mark - // DEFINITIONS //

#define PQChoiceTextDidChangeNotification @"kNotificationPQChoice_TextDidChangeNotification"
#define PQChoiceTextInputDidChangeNotification @"kNotificationPQChoice_TextInputDidChangeNotification"

#define PQChoiceTextDidSaveNotification @"kNotificationPQChoice_TextDidSaveNotification"
#define PQChoiceTextInputDidSaveNotification @"kNotificationPQChoice_TextInputDidSaveNotification"

#define PQChoiceWillBeSavedNotification @"kNotificationPQChoice_WillBeSaved"
#define PQChoiceWasSavedNotification @"kNotificationPQChoice_WasSaved"
#define PQChoiceWillBeRemovedNotification @"kNotificationPQChoice_WillBeRemoved"
#define PQChoiceWillBeDeletedNotification @"kNotificationPQChoice_WillBeDeleted"

#pragma mark - // PROTOCOL (PQChoice) //

@protocol PQChoice <NSObject>

- (NSString *)text;
- (BOOL)textInput;

@end

#pragma mark - // PROTOCOL (PQChoice_Editable) //

@protocol PQChoice_Editable <PQChoice>

// INITIALIZERS //

//- (id)initWithText:(NSString *)text;

// SETTERS //

- (void)setText:(NSString *)text;
- (void)setTextInput:(BOOL)textInput;

@end

#pragma mark - // PROTOCOL (PQChoice_Init) //

@protocol PQChoice_Init <NSObject>

+ (id <PQChoice_Editable>)choiceWithText:(NSString *)text;

@end
