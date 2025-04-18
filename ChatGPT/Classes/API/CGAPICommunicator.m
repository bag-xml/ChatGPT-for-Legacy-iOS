//
//  CGAPICommunicator.m
//  ChatGPT
//
//  Created by XML on 1/13/25.
//  Copyright (c) 2025 XML. All rights reserved.
//

#import "CGAPICommunicator.h"

@implementation CGAPICommunicator

+ (void)createChatCompletionwithContent:(NSMutableArray *)content {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        bool alternative = [[NSUserDefaults standardUserDefaults] boolForKey:@"alternative"];
        [NSNotificationCenter.defaultCenter postNotificationName:@"THINK STATUS" object:nil];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        NSURL *chatCompletionEndpoint = [NSURL URLWithString:[NSString stringWithFormat:@"%@/v1/chat/completions", domain]];
        if(alternative == YES) {
            chatCompletionEndpoint = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/v1/chat/completions", altDomain]];
        }
        NSURLResponse *response;
        NSError *error;
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        
        NSMutableArray *messagesArray = [NSMutableArray array];
        
        for (CGMessage *message in content) {
            if (message.type == 2 && message.imageHash != nil) {
                continue;
            }
            
            NSMutableDictionary *messageDict = [NSMutableDictionary dictionary];
            
            // Set basic role
            [messageDict setObject:(message.role ?: @"user") forKey:@"role"];
            
            NSMutableArray *contentArray = [NSMutableArray array];
            if (message.content && message.content.length > 0) {
                NSDictionary *textContentDict = @{
                                                  @"type": @"text",
                                                  @"text": message.content
                                                  };
                [contentArray addObject:textContentDict];
            }
            if (message.imageHash) {
                NSDictionary *imageContentDict = @{
                                                   @"type": @"image_url",
                                                   @"image_url": @{@"url": [NSString stringWithFormat:@"data:image/jpeg;base64,%@", message.imageHash]}
                                                   };
                [contentArray addObject:imageContentDict];
            }
            
            [messageDict setObject:contentArray forKey:@"content"];
            
            [messagesArray addObject:messageDict];
        }

        NSString *model = [[NSUserDefaults standardUserDefaults] objectForKey:@"c-aiModel"];

        if (!model || [model length] == 0) {
            [CGAPIHelper alert:@"Missing Model" withMessage:@"Please re-check your model settings. Your model was set back to 'gpt-4o-mini' for this session."];
            model = @"gpt-4o-mini";
        }
        
        NSDictionary *body = @{
                               @"model": model,
                               @"messages": messagesArray
                               };

        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
        
        [request setURL:chatCompletionEndpoint];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:jsonData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"Bearer %@", apiKey] forHTTPHeaderField:@"Authorization"];
        

        
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if(data) {
            
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            NSDictionary* parsedResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

            if (!parsedResponse) {
                [NSNotificationCenter.defaultCenter postNotificationName:@"CANCEL LOAD" object:nil];
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                CGMessage *visualEM = [CGAPIHelper loopErrorBack:@"Something went wrong and the response came back **empty**. This message is shown to you as a preventative measure to stop potential crashes. Please make sure you're properly connected to the intenret, re-check your API options and your API key and make sure a proxy isn't interfering"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NSNotificationCenter.defaultCenter postNotificationName:@"AI RESPONSE" object:visualEM];
                });
                return;
            }
            //error handling
            NSDictionary *errorDict = [parsedResponse objectForKey:@"error"];
            if(errorDict) {
                CGMessage *visualEM = [CGAPIHelper loopErrorBack:[errorDict objectForKey:@"message"]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NSNotificationCenter.defaultCenter postNotificationName:@"AI RESPONSE" object:visualEM];
                [CGAPIHelper alert:@"Warning" withMessage:[NSString stringWithFormat:@"%@", [errorDict objectForKey:@"message"]]];
                });
                return;
            }
            
            CGMessage *convertedMessage = [CGAPIHelper convertTextCompletionResponse:parsedResponse];
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSNotificationCenter.defaultCenter postNotificationName:@"AI RESPONSE" object:convertedMessage];
            });
        } else {
            NSLog(@"%@", error);
            [NSNotificationCenter.defaultCenter postNotificationName:@"CANCEL LOAD" object:nil];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            CGMessage *visualEM = [CGAPIHelper loopErrorBack:@"Please make sure you're **connected to a Wi-Fi network or have cellular data enabled**. ChatGPT cannot connect to OpenAI's services at the moment. **Please try again later.**"];
            dispatch_async(dispatch_get_main_queue(), ^{
            [NSNotificationCenter.defaultCenter postNotificationName:@"AI RESPONSE" object:visualEM];
            });
            return;
        }
    });
}

+ (void)createImageGenerationWithContent:(NSString *)content {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:@"THINK STATUS" object:nil];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        NSURL *chatCompletionEndpoint = [NSURL URLWithString:[NSString stringWithFormat:@"%@/v1/images/generations", domain]];
        NSURLResponse *response;
        NSError *error;
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        
        
        NSString *model = [[NSUserDefaults standardUserDefaults] objectForKey:@"i-aiModel"];

        if (!model || [model length] == 0) {
            [CGAPIHelper alert:@"Missing Model" withMessage:@"Please re-check your model settings. Your model was set back to 'dall-e-3' for this session."];
            model = @"dall-e-3";
        }
        
        NSDictionary *body = @{
                               @"model": model,
                               @"prompt": content,
                               @"n": @1,
                               @"size": @"1024x1024",
                               @"response_format": @"b64_json"
                               };
        
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
        
        [request setURL:chatCompletionEndpoint];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:jsonData];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"Bearer %@", apiKey] forHTTPHeaderField:@"Authorization"];
        
        
        
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if(data) {
            
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            NSDictionary* parsedResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            
            //error handling
            NSDictionary *errorDict = [parsedResponse objectForKey:@"error"];
            if(errorDict) {
                CGMessage *visualEM = [CGAPIHelper loopErrorBack:[errorDict objectForKey:@"message"]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NSNotificationCenter.defaultCenter postNotificationName:@"AI RESPONSE" object:visualEM];
                    [CGAPIHelper alert:@"Warning" withMessage:[NSString stringWithFormat:@"%@", [errorDict objectForKey:@"message"]]];
                });
                return;
            }
            
            CGMessage *convertedMessage = [CGAPIHelper convertImageGenerationResponse:parsedResponse];
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSNotificationCenter.defaultCenter postNotificationName:@"AI RESPONSE" object:convertedMessage];
            });
            
        } else {
            [NSNotificationCenter.defaultCenter postNotificationName:@"CANCEL LOAD" object:nil];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            CGMessage *visualEM = [CGAPIHelper loopErrorBack:@"Please make sure you're **connected to a Wi-Fi network or have cellular data enabled**. ChatGPT cannot connect to OpenAI's services at the moment. **Please try again later.**"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSNotificationCenter.defaultCenter postNotificationName:@"AI RESPONSE" object:visualEM];
            });
            return;
        }
    });
    
}
    
@end
