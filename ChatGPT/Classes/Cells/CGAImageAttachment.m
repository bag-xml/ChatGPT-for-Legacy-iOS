//
//  CGAImageAttachment.m
//  ChatGPT
//
//  Created by XML on 18/03/25.
//  Copyright (c) 2025 XML. All rights reserved.
//

#import "CGAImageAttachment.h"

@implementation CGAImageAttachment

- (void)awakeFromNib
{
    // Initialization code
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if(VERSION_MIN(@"7.0")) {
    } else {
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = self.bounds;
        gradient.colors = @[(id)[UIColor colorWithRed:0.922 green:0.922 blue:0.922 alpha:1.0].CGColor, // #ebebeb
                            (id)[UIColor colorWithRed:0.949 green:0.949 blue:0.949 alpha:1.0].CGColor]; // #f2f2f2
        
        gradient.startPoint = CGPointMake(0.5, 0.0);
        gradient.endPoint = CGPointMake(0.5, 1.0);
        
        [self.contentView.layer insertSublayer:gradient atIndex:0];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
