//
//  CGAPIHelper.h
//  ChatGPT
//
//  Created by XML on 1/13/25.
//  Copyright (c) 2025 XML. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Base64.h"
#import "SVProgressHUD.h"

#import "CGMessage.h"
#import "CGConversation.h"

#define domain @"https://api.openai.com"
#define apiKey [[NSUserDefaults standardUserDefaults] objectForKey:@"apiKey"]

//User settable params
#define updateChecks YES

#define UDCheckServer @"http://5.230.249.85:7530"
#define appVersion [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]

#define VERSION_MIN(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#define IS_IPHONE_5 (fabs((double)[[UIScreen mainScreen] bounds].size.height - (double) 568) < DBL_EPSILON)
#define IS_IPHONE_4 (fabs((double)[[UIScreen mainScreen] bounds].size.height - (double) 480) < DBL_EPSILON)
#define IS_IPHONE_3GS (fabs((double)[[UIScreen mainScreen] bounds].size.height - (double) 240) < DBL_EPSILON)

@interface CGAPIHelper : NSObject



+ (CGMessage*)convertTextCompletionResponse:(NSDictionary*)jsonMessage;
+ (CGMessage*)loopErrorBack:(NSString*)errorMessage;

+ (NSMutableArray*)loadConversations;

+ (void)checkForAppUpdate;
+ (void)checkForAPIKeyValidity;
//Miscellaneous functions
+ (void)alert:(NSString*)title withMessage:(NSString*)message;

//Conversation saving, updating, loading and listing logic
+ (void)saveConversationWithArray:(NSMutableArray *)conversationArray withID:(NSString *)uuid withTitle:(NSString *)title;
+ (BOOL)deleteConversationWithUUID:(NSString *)uuid;
@end
