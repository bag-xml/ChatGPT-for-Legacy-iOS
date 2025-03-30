//
//  CGAPICommunicator.h
//  ChatGPT
//
//  Created by XML on 1/13/25.
//  Copyright (c) 2025 XML. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CGMessage.h"
#import "CGAPIHelper.h"

@interface CGAPICommunicator : NSObject

@property (nonatomic, strong) NSMutableArray *activeConnections;

+ (void)createChatCompletionwithContent:(NSMutableArray *)content;
+ (void)createImageGenerationWithContent:(NSString *)content;

@end
