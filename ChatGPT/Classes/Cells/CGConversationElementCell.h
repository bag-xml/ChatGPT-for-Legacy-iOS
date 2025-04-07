//
//  CGConversationElementCell.h
//  ChatGPT
//
//  Created by XML on 23/02/25.
//  Copyright (c) 2025 XML. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CGConversationElementCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *conversationName;
@property (weak, nonatomic) IBOutlet UIImageView *separator;
@property (weak, nonatomic) IBOutlet UIImageView *iOS7Separator;

@property (weak, nonatomic) IBOutlet UIImageView *thumbnail;
@property (weak, nonatomic) IBOutlet UILabel *accessoryLabel;
@end
