//
//  PQQuestionIndex.h
//  PushQuery
//
//  Created by Ken M. Haggerty on 5/18/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

#pragma mark - // NOTES (Public) //

#pragma mark - // IMPORTS (Public) //

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PQQuestion, PQSurvey;

#pragma mark - // PROTOCOLS //

#pragma mark - // DEFINITIONS (Public) //

NS_ASSUME_NONNULL_BEGIN

@interface PQQuestionIndex : NSManagedObject
@end

NS_ASSUME_NONNULL_END

#import "PQQuestionIndex+CoreDataProperties.h"