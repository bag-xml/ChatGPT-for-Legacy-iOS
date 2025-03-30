//
//  CGChatViewController.h
//  ChatGPT
//
//  Created by XML on 1/13/25.
//  Copyright (c) 2025 XML. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TRMalleableFrameView.h"
#import "Base64.h"
#import "APLSlideMenuViewController.h"

#import "CGAPIHelper.h"
#import "CGMessage.h"
#import "CGAPICommunicator.h"

#import "CGImageViewController.h"

#import "CGImageAttachment.h"
#import "CGAImageAttachment.h"

#import "CGChatTableCell.h"
#import "CGAuthorTableCell.h"


@interface CGChatViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *chatTableView;
@property (weak, nonatomic) IBOutlet UIView *typeView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (weak, nonatomic) IBOutlet UIView *welcomeView;

@property (weak, nonatomic) IBOutlet UIView *inputView;
@property (weak, nonatomic) IBOutlet UITextView *inputField;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *photoButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *topRightButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *hamburgerButton;

@property (weak, nonatomic) IBOutlet UILabel *inputFieldPlaceholder;

@property (weak, nonatomic) IBOutlet UIView *attachmentView;
@property (weak, nonatomic) IBOutlet UIImageView *attachmentMask;
@property (weak, nonatomic) IBOutlet UIImageView *attachmentImage;

@property (strong, nonatomic) NSString *currentImage;

//welcom


@property UIImage *selectedImage;
@property NSString *currentConversationID;
//@property NSString
@property NSMutableArray* messages;
@property bool viewingPresentTime;
@property bool done;
@property bool notTheAlert;

@property UIRefreshControl *reloadControl;

@property (nonatomic, strong) UIPopoverController *imagePopoverController;

- (void)loadChat:(NSMutableArray *)messages withUUID:(NSString *)uuid;
- (void)startNewConversation;

- (int)countOfMessages;

@end
