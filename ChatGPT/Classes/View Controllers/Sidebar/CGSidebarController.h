//
//  CGSidebarController.h
//  ChatGPT
//
//  Created by XML on 23/02/25.
//  Copyright (c) 2025 XML. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CGAPIHelper.h"
#import "CGMessage.h"
#import "CGConversation.h"

#import "CGChatViewController.h"
#import "CGConversationElementCell.h"

@interface CGSidebarController : UITableViewController

@property NSIndexPath *selectedIndexPath;
@property NSMutableArray *allConversations;
@end
