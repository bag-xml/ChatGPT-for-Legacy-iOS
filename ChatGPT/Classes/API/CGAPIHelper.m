//
//  CGAPIHelper.m
//  ChatGPT
//
//  Created by XML on 1/13/25.
//  Copyright (c) 2025 XML. All rights reserved.
//

#import "CGAPIHelper.h"

@implementation CGAPIHelper

+ (void)checkForAppUpdate {
    //this is just via the "XML Update Server"
    //disable this if you'd like (check the header)
    if(updateChecks == YES) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL *randomEndpoint = [NSURL URLWithString:[NSString stringWithFormat:@"%@/update?v=%@", UDCheckServer, appVersion]];
            NSURLResponse *response;
            NSError *error;
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            [request setURL:randomEndpoint];
            [request setHTTPMethod:@"GET"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            
            if(data) {
                NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                bool update = [response objectForKey:@"outdated"];
                NSString *message = [response objectForKey:@"message"];
                
                if(update) {
                    [CGAPIHelper alert:@"Good news!" withMessage:message];
                }
            } else {
                return;
            }
        });
    }
    return;
}

+ (void)checkForAPIKeyValidity {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *randomEndpoint = [NSURL URLWithString:[NSString stringWithFormat:@"%@/v1/models", domain]];
        NSURLResponse *response;
        NSError *error;

        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:randomEndpoint];
        [request setHTTPMethod:@"GET"];
        [request setHTTPBody:nil];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"Bearer %@", apiKey] forHTTPHeaderField:@"Authorization"];
        
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if(data) {
            NSDictionary* parsedResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            NSDictionary *errorDict = [parsedResponse objectForKey:@"error"];
            if(errorDict) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [CGAPIHelper alert:@"Warning" withMessage:[NSString stringWithFormat:@"%@", [errorDict objectForKey:@"message"]]];
                });
                return;
            }
        } else if(!data) {
            if(error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                [CGAPIHelper alert:@"Fatal Error" withMessage:@"Please check your internet connection."];
                });
                return;
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                [CGAPIHelper alert:@"Fatal Error" withMessage:[NSString stringWithFormat:@"An unknown error has occured."]];
                });
                return;
            }
        }
    });
}

+ (void)saveConversationWithArray:(NSMutableArray *)conversationArray withID:(NSString *)uuid withTitle:(NSString *)title{
    NSMutableArray *messagesArray = [NSMutableArray array];
    for (CGMessage *message in conversationArray) {
        NSDictionary *messageDict = @{
                                      @"name": message.author ?: @"You",
                                      @"role": message.role ?: @"user",
                                      @"type": @(message.type),
                                      @"message": message.content ?: @""
                                      };
        [messagesArray addObject:messageDict];
        
        if (message.imageHash) {
            NSDictionary *imageContentDict = @{
                                               @"name": message.author ?: @"You",
                                               @"role": message.role ?: @"user",
                                               @"type": @(message.type),
                                               @"message": message.content ?: @"",
                                               @"image": @{@"url": [NSString stringWithFormat:@"data:image/jpeg;base64,%@", message.imageHash]}
                                               };
            [messagesArray addObject:imageContentDict];
        }
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd-MM-yyyy"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString *ConvTitle = title;
    if([title isEqualToString:@"Chat"]) {
        ConvTitle = [NSString stringWithFormat:@"Chat, at %@", dateString];
    }
    NSDictionary *conversationDict = @{
                                       @"conversationID": uuid,
                                       @"title": ConvTitle,
                                       @"createdAt": dateString,
                                       @"messages": messagesArray
                                       }; //add exact time measurements to edits
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:conversationDict options:NSJSONWritingPrettyPrinted error:nil];

    NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", uuid]]];
    // Write data using writeToURL]
    BOOL success = [jsonData writeToURL:fileURL options:NSDataWritingAtomic error:nil];
    if (success)
        return;
}

+ (NSMutableArray*)loadConversations {
    NSMutableArray *conversations = [NSMutableArray array];
    
    NSString *directoryPath = NSTemporaryDirectory();
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:nil];
    
    for (NSString *fileName in files) {
        if (![fileName hasSuffix:@".json"]) continue;
        NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        NSDictionary *conversationDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        CGConversation *conversation = CGConversation.new;
        conversation.uuid = conversationDict[@"conversationID"];
        conversation.title = conversationDict[@"title"];
        conversation.creationDate = conversationDict[@"createdAt"];
        conversation.messages = [NSMutableArray array];
        
        NSArray *messagesArray = conversationDict[@"messages"];
        conversation.messageCount = (int)messagesArray.count;
        
        for (NSDictionary *messageDict in messagesArray) {
            CGMessage *message = CGMessage.new;
            message.role = messageDict[@"role"];
            message.type = [messageDict[@"type"] intValue];
            message.content = messageDict[@"message"];
            
            float contentWidth = UIScreen.mainScreen.bounds.size.width - 63;
            CGSize textSize = [message.content sizeWithFont:[UIFont systemFontOfSize:15]
                                             constrainedToSize:CGSizeMake(contentWidth, MAXFLOAT)
                                                 lineBreakMode:NSLineBreakByWordWrapping];
            message.contentHeight = textSize.height + 50;
            
            message.author = messageDict[@"name"];
            if(message.type == 1) {
                message.avatar = [UIImage imageNamed:@"missingAvatar"];
            } else if(message.type == 2) {
                message.avatar = [UIImage imageNamed:@"defaultAssistantAvatar"];
            }
            
            
            
            if (messageDict[@"image"] && [messageDict[@"image"] isKindOfClass:[NSDictionary class]]) {
                NSString *imageURL = messageDict[@"image"][@"url"];
                if ([imageURL hasPrefix:@"data:image/jpeg;base64,"]) {
                    NSString *base64String = [imageURL stringByReplacingOccurrencesOfString:@"data:image/jpeg;base64," withString:@""];
                    
                    NSData *imageData = [NSData dataWithBase64EncodedString:base64String];
                    message.imageAttachment = [UIImage imageWithData:imageData];
                }
            

            }
            [conversation.messages addObject:message];
        }
        [conversations addObject:conversation];
    }
    return conversations;
}

+ (BOOL)deleteConversationWithUUID:(NSString *)uuid {
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", uuid]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:filePath]) {
        BOOL success = [fileManager removeItemAtPath:filePath error:nil];
        if (success) {
            return YES;
        } else {
            [CGAPIHelper alert:@"Error" withMessage:@"An error occured when trying to delete this conversation."];
            return NO;
        }
    } else {
        [CGAPIHelper alert:@"Error" withMessage:@"An error occured when trying to delete this conversation."];
        return NO;
    }
}

+ (CGMessage*)convertTextCompletionResponse:(NSDictionary*)jsonMessage {
    NSDictionary *firstChoice = jsonMessage[@"choices"][0];
    NSDictionary *messageDict = firstChoice[@"message"];
    
    CGMessage *newAssistantResponseMessage = CGMessage.new;
    
    newAssistantResponseMessage.author = @"ChatGPT";
    newAssistantResponseMessage.content = [messageDict objectForKey:@"content"];
    newAssistantResponseMessage.role = [messageDict objectForKey:@"role"];
    newAssistantResponseMessage.avatar = [UIImage imageNamed:@"defaultAssistantAvatar"];
    newAssistantResponseMessage.type = 2; //AI Message is 2, user 1, errors 3
    newAssistantResponseMessage.indestructible = YES;
    
    float contentWidth = UIScreen.mainScreen.bounds.size.width - 63;
    CGSize textSize = [newAssistantResponseMessage.content sizeWithFont:[UIFont systemFontOfSize:15] constrainedToSize:CGSizeMake(contentWidth, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping];
    newAssistantResponseMessage.contentHeight = textSize.height + 50;

    return newAssistantResponseMessage;
}

+ (CGMessage*)loopErrorBack:(NSString*)errorMessage {
    CGMessage *newError = CGMessage.new;
    
    newError.author = @"ChatGPT";
    newError.content = errorMessage;
    newError.type = 2; //AI Message is 2, user 1, errors 3 //temporary at 2
    newError.indestructible = YES;
    newError.avatar = [UIImage imageNamed:@"defaultAssistantAvatar"];
    
    float contentWidth = UIScreen.mainScreen.bounds.size.width - 63;
    CGSize textSize = [newError.content sizeWithFont:[UIFont systemFontOfSize:15] constrainedToSize:CGSizeMake(contentWidth, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping];
    newError.contentHeight = textSize.height + 50;
    return newError;
}


+ (void)alert:(NSString*)title withMessage:(NSString*)message{
	dispatch_async(dispatch_get_main_queue(), ^{
		UIAlertView *alert = [UIAlertView.alloc
                              initWithTitle: title
                              message: message
                              delegate: nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
		[alert show];
	});
}




@end
