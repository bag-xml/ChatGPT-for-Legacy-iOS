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
    NSLog(@"Scott Forstall");
    TSMarkdownParser *parser = [TSMarkdownParser standardParser];
    NSLog(@"Scott Forstall 1");
    
    NSAttributedString *attributedText = [parser attributedStringFromMarkdown:messageText];
    if (attributedText) {
        NSLog(@"Attributed text created successfully.");
    } else {
        NSLog(@"Error: Attributed text creation failed.");
    }
    
    self.contentTextView.attributedText = attributedText;
    NSLog(@"Scott Forstall 2");
    [self adjustTextViewSize];
    NSLog(@"Scott Forstall 3");
}


- (void)adjustTextViewSize {
    CGSize maxSize = CGSizeMake(self.contentTextView.frame.size.width, CGFLOAT_MAX);
    CGSize newSize = [self.contentTextView sizeThatFits:maxSize];
    
    CGRect newFrame = self.contentTextView.frame;
    newFrame.size.height = newSize.height;
    self.contentTextView.frame = newFrame;
}

@end
