//
//  CGChatTableCell.m
//  ChatGPT
//
//  Created by XML on 18/01/25.
//  Copyright (c) 2025 XML. All rights reserved.
//

#import "CGChatTableCell.h"

@implementation CGChatTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
