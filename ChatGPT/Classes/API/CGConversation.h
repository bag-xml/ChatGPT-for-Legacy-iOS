//
//  CGConversation.h
//  ChatGPT
//
//  Created by XML on 23/02/25.
//  Copyright (c) 2025 XML. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CGConversation : NSObject

@property NSString *uuid;
@property NSString *creationDate;
@property NSString *lastTimeEdited;
@property NSString *title;
@property int messageCount;

@property NSMutableArray *messages;


@end
