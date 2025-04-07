//
//  CGImageAttachment.h
//  ChatGPT
//
//  Created by XML on 18/03/25.
//  Copyright (c) 2025 XML. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CGAPIHelper.h"

@interface CGImageAttachment : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *thumbnail;
@property (weak, nonatomic) IBOutlet UIView *totalThumbView;
@property (weak, nonatomic) IBOutlet UIImageView *thumbMask;

@end
