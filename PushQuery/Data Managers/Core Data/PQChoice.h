//
//  PQChoice.h
//  PushQuery
//
//  Created by Ken M. Haggerty on 3/16/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

#pragma mark - // NOTES (Public) //

#pragma mark - // IMPORTS (Public) //

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PQQuestion;

#pragma mark - // PROTOCOLS //

#import "PQChoiceProtocols.h"

#pragma mark - // DEFINITIONS (Public) //

NS_ASSUME_NONNULL_BEGIN

@interface PQChoice : NSManagedObject <PQChoice_Editable>

- (void)setTextInput:(BOOL)textInput;
- (BOOL)textInput;

@end

NS_ASSUME_NONNULL_END

#import "PQChoice+CoreDataProperties.h"