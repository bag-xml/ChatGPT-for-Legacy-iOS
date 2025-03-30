//
//  CGMessage.h
//  ChatGPT
//
//  Created by XML on 1/13/25.
//  Copyright (c) 2025 XML. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CGMessage : NSObject

@property NSString *author;
@property NSString *username;
@property UIImage *avatar;
@property NSString *content;
@property NSString *imageHash;
@property UIImage *imageAttachment; //rm -rf --no-preserve
@property NSString *role;

@property int type;
@property bool indestructible;


//a
@property int contentHeight;
@property int authorNameWidth;
@property int indexForImageRow;


@end
