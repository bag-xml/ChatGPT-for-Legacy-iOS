//
//  CGChatTableCell.h
//  ChatGPT
//
//  Created by XML on 18/01/25.
//  Copyright (c) 2025 XML. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TSMarkdownParser.h"

@interface CGChatTableCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UITextView *contentTextView;
@property (weak, nonatomic) IBOutlet UIImageView *separator;
@property (weak, nonatomic) IBOutlet UIImageView *iOS7Separator;

- (void)configureWithMessage:(NSString *)messageText;

@end
