//
//  CGChatTableCell.m
//  ChatGPT
//
//  Created by XML on 18/01/25.
//  Copyright (c) 2025 XML. All rights reserved.
//

#import "CGChatTableCell.h"

@implementation CGChatTableCell

- (void)configureWithMessage:(NSString *)messageText {
    TSMarkdownParser *parser = [TSMarkdownParser standardParser];

    NSAttributedString *attributedText = [parser attributedStringFromMarkdown:messageText];
    if (attributedText) {
    } else {
    }
    
    self.contentTextView.attributedText = attributedText;
    [self adjustTextViewSize];
}


- (void)adjustTextViewSize {
    CGSize maxSize = CGSizeMake(self.contentTextView.frame.size.width, CGFLOAT_MAX);
    CGSize newSize = [self.contentTextView sizeThatFits:maxSize];
    
    CGRect newFrame = self.contentTextView.frame;
    newFrame.size.height = newSize.height;
    self.contentTextView.frame = newFrame;
}

@end
