//
//  PQCoreDataController+PRIVATE.h
//  PushQuery
//
//  Created by Ken M. Haggerty on 4/20/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

#pragma mark - // NOTES //

#pragma mark - // IMPORTS //

#import "PQCoreDataController.h"

#pragma mark - // PROTOCOLS //

#pragma mark - // DEFINITIONS //

@interface PQCoreDataController (PRIVATE)

+ (PQUser *)userWithUserId:(NSString *)userId;
+ (PQSurvey *)surveyWithSurveyId:(NSString *)surveyId authorId:(NSString *)authorId;
+ (PQQuestion *)questionWithQuestionId:(NSString *)questionId surveyId:(NSString *)surveyId;
+ (PQResponse *)responseWithResponseId:(NSString *)responseId questionId:(NSString *)questionId;

@end
