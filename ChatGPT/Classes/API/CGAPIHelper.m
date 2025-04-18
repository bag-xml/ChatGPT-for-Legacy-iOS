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
                
                NSNumber *update = response[@"outdated"];
                NSString *message = response[@"message"];
                
                if ([update intValue] == 1) {
                    [CGAPIHelper alert:@"Good news!" withMessage:message];
                } else {
                    return;
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
        bool alternative = [[NSUserDefaults standardUserDefaults] boolForKey:@"alternative"];
        NSURL *randomEndpoint = [NSURL URLWithString:[NSString stringWithFormat:@"%@/v1/models", domain]];
        if(alternative == YES) {
            randomEndpoint = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/v1/key", altDomain]];
        }
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
            if(!parsedResponse) {
                NSLog(@"NO NO NO");
            } else {
                NSLog(@"%@", parsedResponse);
            }
            NSDictionary *errorDict = [parsedResponse objectForKey:@"error"];
            if(errorDict) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [CGAPIHelper alert:@"Warning" withMessage:[NSString stringWithFormat:@"%@", [errorDict objectForKey:@"message"]]];
                });
                
                return;
            } else if(!errorDict) {
                //[NSNotificationCenter.defaultCenter postNotificationName:@"KEY IS VALID" object:nil];
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

/*+ (void)logInUserwithKey:(NSString*)key {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        bool alternative = [[NSUserDefaults standardUserDefaults] boolForKey:@"alternative"];
        NSURL *randomEndpoint = [NSURL URLWithString:[NSString stringWithFormat:@"%@/v1/me", domain]];
        if(alternative == YES) {
            randomEndpoint = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/v1/key", altDomain]];
        }
        NSLog(@"%@", randomEndpoint);
        NSURLResponse *response;
        NSError *error;
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:randomEndpoint];
        [request setHTTPMethod:@"GET"];
        [request setHTTPBody:nil];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"Bearer %@", key] forHTTPHeaderField:@"Authorization"];
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if(data) {
            NSDictionary* parsedResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if(!parsedResponse) {
                [NSNotificationCenter.defaultCenter postNotificationName:@"LOG-IN FAILURE" object:nil];
                return;
            } else {
                NSLog(@"%@", parsedResponse);
            }
            
            //[NSNotificationCenter.defaultCenter postNotificationName:@"LOG-IN VALID" object:nil];
        } else if(!data) {
            [NSNotificationCenter.defaultCenter postNotificationName:@"LOG-IN FAILURE" object:nil];
            return;
        }
            
    });
}
*/

+ (void)logInUserwithKey:(NSString*)key {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        bool alternative = [[NSUserDefaults standardUserDefaults] boolForKey:@"alternative"];
        NSURL *randomEndpoint = [NSURL URLWithString:[NSString stringWithFormat:@"%@/v1/me", domain]];
        if(alternative == YES) {
            randomEndpoint = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/v1/key", altDomain]];
        }
        NSLog(@"%@", randomEndpoint);
        NSURLResponse *response;
        NSError *error;
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:randomEndpoint];
        [request setHTTPMethod:@"GET"];
        [request setHTTPBody:nil];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"Bearer %@", key] forHTTPHeaderField:@"Authorization"];
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if(data) {
            NSDictionary* parsedResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if(!parsedResponse) {
                [NSNotificationCenter.defaultCenter postNotificationName:@"LOG-IN FAILURE" object:nil];
                return;
            }
            
            NSDictionary *errorDict = [parsedResponse objectForKey:@"error"];
            if(errorDict) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [CGAPIHelper alert:@"Warning" withMessage:[NSString stringWithFormat:@"%@", [errorDict objectForKey:@"message"]]];
                    [NSNotificationCenter.defaultCenter postNotificationName:@"LOG-IN FAILURE" object:nil];
                });
                
                return;
            }
            
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasLoggedInUser"];
            [[NSUserDefaults standardUserDefaults] setObject:@"You" forKey:@"username"];
            [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"apiKey"];
            
            
            if(alternative == NO) {
                [[NSUserDefaults standardUserDefaults] setObject:parsedResponse[@"email"] forKey:@"email"];
                [[NSUserDefaults standardUserDefaults] setObject:parsedResponse[@"name"] forKey:@"username"];
                
                id pictureValue = parsedResponse[@"picture"];
                if (pictureValue && pictureValue != [NSNull null]) {
                    NSURL *imageURL = [NSURL URLWithString:pictureValue];
                    if (imageURL) {
                        NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
                        if (imageData) {
                            NSString *tmpDirectory = NSTemporaryDirectory();
                            NSString *filePath = [tmpDirectory stringByAppendingPathComponent:@"avatar.png"];
                            BOOL success = [imageData writeToFile:filePath options:NSDataWritingAtomic error:&error];
                            if (!success) {
                                [self alert:@"Error" withMessage:@"An error occured when trying to download the user avatar."];
                            }
                        }
                    }
                }
            }
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [NSNotificationCenter.defaultCenter postNotificationName:@"LOG-IN VALID" object:nil];
        } else if(!data) {
            [NSNotificationCenter.defaultCenter postNotificationName:@"LOG-IN FAILURE" object:nil];
            return;
        }
        
    });
}


+ (void)saveConversationWithArray:(NSMutableArray *)conversationArray withID:(NSString *)uuid withTitle:(NSString *)title{
    NSMutableArray *messagesArray = [NSMutableArray array];
    for (CGMessage *message in conversationArray) {
        NSMutableDictionary *messageDict = [@{
                                              @"name": message.author ?: @"You",
                                              @"role": message.role ?: @"user",
                                              @"type": @(message.type),
                                              @"message": message.content ?: @""
                                              } mutableCopy];
        
        if (message.imageHash) {
            messageDict[@"image"] = @{@"url": [NSString stringWithFormat:@"data:image/jpeg;base64,%@", message.imageHash]};
        }
        
        [messagesArray addObject:messageDict];
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
                //hmm
                NSString *filePath = [directoryPath stringByAppendingPathComponent:@"avatar.png"];
                UIImage *image = [UIImage imageWithContentsOfFile:filePath];
                
                if (image) {
                    message.avatar = image;
                } else {
                    message.avatar = [UIImage imageNamed:@"defaultUserAvatar"];
                }
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

+ (BOOL)deleteAllConversations {
    NSString *tempDirectory = NSTemporaryDirectory();
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    
    NSArray *files = [fileManager contentsOfDirectoryAtPath:tempDirectory error:&error];
    BOOL allDeleted = YES;
    
    for(NSString *file in files) {
        if([file.pathExtension isEqualToString:@"json"]) {
            NSString *filePath = [tempDirectory stringByAppendingPathComponent:file];
            BOOL success = [fileManager  removeItemAtPath:filePath error:&error];
            
            if(!success) {
                allDeleted = NO;
            }
        }
    }
    
    if(!allDeleted) {
        [CGAPIHelper alert:@"Error" withMessage:@"An error occured while trying to delete conversations."];
    }
    return allDeleted;
}
+ (CGMessage*)convertTextCompletionResponse:(NSDictionary*)jsonMessage {
    NSDictionary *firstChoice = jsonMessage[@"choices"][0];
    NSDictionary *messageDict = firstChoice[@"message"];
    
    CGMessage *newAssistantResponseMessage = CGMessage.new;
    
    newAssistantResponseMessage.author = @"ChatGPT";
    newAssistantResponseMessage.content = [messageDict objectForKey:@"content"];
    newAssistantResponseMessage.role = [messageDict objectForKey:@"role"];
    if(VERSION_MIN(@"7.0")) {
        newAssistantResponseMessage.avatar = [UIImage imageNamed:@"iOS7AssistantAvatar"];
    } else {
        newAssistantResponseMessage.avatar = [UIImage imageNamed:@"defaultAssistantAvatar"];
    }
    newAssistantResponseMessage.type = 2; //AI Message is 2, user 1, errors 3
    newAssistantResponseMessage.indestructible = YES;
    
    float contentWidth = UIScreen.mainScreen.bounds.size.width - 63;
    CGSize textSize = [newAssistantResponseMessage.content sizeWithFont:[UIFont systemFontOfSize:15] constrainedToSize:CGSizeMake(contentWidth, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping];
    newAssistantResponseMessage.contentHeight = textSize.height + 50;

    return newAssistantResponseMessage;
}

+ (CGMessage*)convertImageGenerationResponse:(NSDictionary*)jsonMessage {
    NSDictionary *firstData = jsonMessage[@"data"][0];
    
    
    CGMessage *newAssistantResponseMessage = CGMessage.new;
    
    newAssistantResponseMessage.author = @"ChatGPT";
    newAssistantResponseMessage.content = firstData[@"revised_prompt"];
    newAssistantResponseMessage.imageHash = firstData[@"b64_json"];
    
    NSData *imageData = [NSData dataWithBase64EncodedString:firstData[@"b64_json"]];
    newAssistantResponseMessage.imageAttachment = [UIImage imageWithData:imageData];
    
    newAssistantResponseMessage.role = @"assistant";
    if(VERSION_MIN(@"7.0")) {
        newAssistantResponseMessage.avatar = [UIImage imageNamed:@"iOS7AssistantAvatar"];
    } else {
        newAssistantResponseMessage.avatar = [UIImage imageNamed:@"defaultAssistantAvatar"];
    }
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
    
    if(VERSION_MIN(@"7.0")) {
        newError.avatar = [UIImage imageNamed:@"iOS7AssistantAvatar"];
    } else {
        newError.avatar = [UIImage imageNamed:@"defaultAssistantAvatar"];
    }
    
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


/*
+ (void)logInUserwithKey:(NSString*)key {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        bool alternative = [[NSUserDefaults standardUserDefaults] boolForKey:@"alternative"];
        NSURL *randomEndpoint = [NSURL URLWithString:[NSString stringWithFormat:@"%@/v1/me", domain]];
        if(alternative == YES) {
            randomEndpoint = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/v1/user", altDomain]];
        }
        NSLog(@"%@", randomEndpoint);
        NSURLResponse *response;
        NSError *error;
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:randomEndpoint];
        [request setHTTPMethod:@"GET"];
        [request setHTTPBody:nil];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"Bearer %@", key] forHTTPHeaderField:@"Authorization"];
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if(data) {
            NSDictionary* parsedResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if(!parsedResponse) {
                [NSNotificationCenter.defaultCenter postNotificationName:@"LOG-IN FAILURE" object:nil];
                return;
            }
            NSDictionary *errorDict = [parsedResponse objectForKey:@"error"];
            if(errorDict) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [CGAPIHelper alert:@"Warning" withMessage:[NSString stringWithFormat:@"%@", [errorDict objectForKey:@"message"]]];
                    [NSNotificationCenter.defaultCenter postNotificationName:@"LOG-IN FAILURE" object:nil];
                });
                
                return;
            }
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasLoggedInUser"];
            
            [[NSUserDefaults standardUserDefaults] setObject:parsedResponse[@"email"] forKey:@"email"];
            [[NSUserDefaults standardUserDefaults] setObject:parsedResponse[@"name"] forKey:@"username"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            id pictureValue = parsedResponse[@"picture"];
            if (pictureValue && pictureValue != [NSNull null]) {
                NSURL *imageURL = [NSURL URLWithString:pictureValue];
                if (imageURL) {
                    NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
                    if (imageData) {
                        NSString *tmpDirectory = NSTemporaryDirectory();
                        NSString *filePath = [tmpDirectory stringByAppendingPathComponent:@"avatar.png"];
                        BOOL success = [imageData writeToFile:filePath options:NSDataWritingAtomic error:&error];
                        if (!success) {
                            [self alert:@"Error" withMessage:@"An error occured when trying to download the user avatar."];
                        }
                    }
                }
            }
            
            
            [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"apiKey"];
            [NSNotificationCenter.defaultCenter postNotificationName:@"LOG-IN VALID" object:nil];
        } else if(!data) {
            [NSNotificationCenter.defaultCenter postNotificationName:@"LOG-IN FAILURE" object:nil];
            return;
        }
        
    });
}*/

@end
