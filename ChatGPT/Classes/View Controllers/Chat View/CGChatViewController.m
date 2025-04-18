//
//  CGChatViewController.m
//  ChatGPT
//
//  Created by XML on 1/13/25.
//  Copyright (c) 2025 XML. All rights reserved.
//

#import "CGChatViewController.h"

@interface CGChatViewController ()

@end

@implementation CGChatViewController

- (void)viewWillAppear:(BOOL)animated {
    if(VERSION_MIN(@"7.0")) {
    } else {
        NSDictionary *titleTextAttributes = @{
                                              UITextAttributeTextColor: [UIColor colorWithRed:74/255.0 green:125/255.0 blue:112/255.0 alpha:1.0],
                                              UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
                                              UITextAttributeTextShadowColor: [UIColor whiteColor]
                                              };
        [self.navigationController.navigationBar setTitleTextAttributes:titleTextAttributes];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleAIResponse:) name:@"AI RESPONSE" object:nil];
    //[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleThinkingStatus:) name:@"THINK STATUS" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(saveCurrentChat:) name:@"SAVE CHAT" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(retrieveUserThings:) name:@"KEY IS VALID" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(cancelLoad) name:@"CANCEL LOAD" object:nil];
    self.slideMenuController.bouncing = YES;
    self.slideMenuController.gestureSupport = APLSlideMenuGestureSupportDrag;
    self.slideMenuController.separatorColor = [UIColor grayColor];
    
    self.chatTableView.delegate = self;
    self.chatTableView.dataSource = self;
    self.messages = [NSMutableArray array];
    
    bool firstLaunch = [[NSUserDefaults standardUserDefaults] boolForKey:@"firstLaunch"];
    if(firstLaunch == NO) {
        [self prepareFirstLaunch];
    } else {
        NSLog(@"wtf");
        [self checkAPICredentials];
    }
     
    self.attachmentView.hidden = YES;
    self.attachmentImage.image = nil;
    self.attachmentImage.layer.cornerRadius = self.attachmentImage.frame.size.width / 8.0;
    self.attachmentImage.layer.masksToBounds = YES;
    
    if(self.currentConversationID == nil) {
        [self setCurrentConversationUniqueID:nil];
    }
    self.welcomeView.alpha = 0.0;
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"aFL"] == YES) {
        [self displayWelcomeLaunchView];
    }
    
    [CGAPIHelper checkForAppUpdate];
    [self.inputField setDelegate:self];
    [[self.inputView layer] setMasksToBounds:YES];
    
    if(VERSION_MIN(@"7.0")) {
        self.chatTableView.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1.0];
            [[self.inputView layer] setCornerRadius:7.25f];
        self.IVOverlayImage.image = [UIImage imageNamed:@"iOS7InputOverlay"];
        self.inputFieldPlaceholder.textColor = [UIColor colorWithRed:174/255.0 green:174/255.0 blue:174/255.0 alpha:1.0];
        self.inputField.textColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0];
        [self.sendButton setImage:nil];
        //[self.hamburgerButton setImage:[UIImage imageNamed:@"IOS7HamburgerGlyph.png"]];
        [self.hamburgerButton setImage:[[UIImage imageNamed:@"hamburgerButton"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        [self.sendButton setTitle:@"Send"];//iOS7HamburgerGlyph
        self.attachmentMask.image = [UIImage imageNamed:@"iOS7ImageViewOL"];
        
        self.WelcomeImage.image = [UIImage imageNamed:@"iOS7icon"];

        self.LThinkLabel.shadowColor = nil;
        self.LUserLabel.shadowColor = nil;
        self.LAvatar.image = [UIImage imageNamed:@"iOS7AssistantAvatar"];
        
        self.WelcomeHead.shadowColor = nil;

    } else {
        //[self.hamburgerButton setImage:[[UIImage imageNamed:@"IOS7HamburgerGlyph.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"bar-BG"] forBarMetrics:UIBarMetricsDefault];
        [self.sendButton setBackgroundImage:[UIImage imageNamed:@"SendBarButton"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [self.sendButton setBackgroundImage:[UIImage imageNamed:@"SendBarButtonPressed"] forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
        
        [self.hamburgerButton setBackgroundImage:[UIImage imageNamed:@"BarButton"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [self.hamburgerButton setBackgroundImage:[UIImage imageNamed:@"BarButtonPressed"] forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
        
        [self.topRightButton setBackgroundImage:[UIImage imageNamed:@"BarButton"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [self.topRightButton setBackgroundImage:[UIImage imageNamed:@"BarButtonPressed"] forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
        
        [self.photoButton setBackgroundImage:[UIImage imageNamed:@"BarButton"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [self.photoButton setBackgroundImage:[UIImage imageNamed:@"BarButtonPressed"] forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
        [self.toolbar setBackgroundImage:[UIImage imageNamed:@"bar-BG"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
        [[self.inputView layer] setCornerRadius:14.5f];
    }

    self.inputFieldPlaceholder.hidden = NO;
}

- (void)handleAIResponse:(NSNotification *)notification {
    CGMessage *Response = notification.object;
    [self slideUpTypeView];
    [self.messages addObject:Response];
    [self.chatTableView reloadData];
    if(self.viewingPresentTime)
        [self.chatTableView setContentOffset:CGPointMake(0, self.chatTableView.contentSize.height - self.chatTableView.frame.size.height) animated:YES];
    
    if (self.messages.count >= 5 && self.messages.count <= 17) {
        if(self.done == NO)
            [self invokeTitleChange];
    }

}

- (void)retrieveUserThings:(NSNotification *)notification {

}
- (void)saveCurrentChat:(NSNotification *)notification {
    if (self.messages.count > 0) {
        [CGAPIHelper saveConversationWithArray:self.messages withID:self.currentConversationID withTitle:self.navigationItem.title];
    }
}

- (void)cancelLoad {
    [self slideUpTypeView];
}
- (void)prepareFirstLaunch {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:@"welcome" sender:self];
    });
}
- (void)loadChat:(NSMutableArray *)messages withUUID:(NSString *)uuid {
    self.messages = nil;
    self.messages = messages;
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"aFL"];
    self.welcomeView.alpha = 0.0; // Fade out
    self.welcomeView = nil; // Release reference
    
    if(messages.count < 6)
        self.done = NO;
    [self setCurrentConversationUniqueID:uuid];
    [self.chatTableView reloadData];
}

- (void)tappedImage:(UITapGestureRecognizer *)gesture {
    UIView *tappedView = gesture.view; // totalThumbView
    UIView *cellView = VERSION_MIN(@"7.0") ? tappedView.superview.superview.superview : tappedView.superview.superview;
    CGImageAttachment *cell = (CGImageAttachment *)cellView;
    UIImage *selectedImage = cell.thumbnail.image;
    if (selectedImage) {
        self.selectedImage = selectedImage;
        [self performSegueWithIdentifier:@"to Viewer" sender:self];
    }
}



- (void)startNewConversation {
    
    [self.inputField resignFirstResponder];
    self.inputField.text = @"";
    
    if (self.typeView.frame.origin.y == 30) {
        [self slideUpTypeView];
    }
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"aFL"];
    self.welcomeView.alpha = 0.0; // Fade out
    self.welcomeView = nil; // Release reference
    
    
   
    [self setCurrentConversationUniqueID:nil];
    self.messages = NSMutableArray.new;
    [self.chatTableView reloadData];
    self.done = NO;
}

- (void)displayWelcomeLaunchView {
    [UIView animateWithDuration:0.33 animations:^{
        self.welcomeView.alpha = 1.0;
    }];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"aFL"] == YES) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"aFL"];
        [UIView animateWithDuration:0.33 animations:^{
            self.welcomeView.alpha = 0.0; // Fade out
        } completion:^(BOOL finished) {
            if (finished) {
                self.welcomeView = nil; // Release reference
            }
        }];
    } else {
        return;
    }
}


- (IBAction)send:(id)sender {
    NSString *trimmedText = [self.inputField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\b(draw|illustrate|generate an image|generate an|generate me an image|image of|create a picture of|show me an image of)\\b"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSRange range = NSMakeRange(0, [trimmedText length]);
    NSUInteger matches = [regex numberOfMatchesInString:trimmedText options:0 range:range];
    
    
    //now for ruling out
    if (trimmedText.length == 0) {
        [self.inputField resignFirstResponder];
        return;
    }
    
    if (trimmedText.length < 3) {
        [CGAPIHelper alert:@"Too short" withMessage:@"For the sake of preserving your API Credit, you should ask the AI questions that are longer than three characters."];
        return;
    }
    
    CGMessage *ownMessage = CGMessage.new;
    
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    NSString *tmpDirectory = NSTemporaryDirectory();
    NSString *filePath = [tmpDirectory stringByAppendingPathComponent:@"avatar.png"];
    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
    
    ownMessage.author = (username.length >= 3) ? username : @"You";
    if(VERSION_MIN(@"7.0")) {
        ownMessage.avatar = image ?: [UIImage imageNamed:@"iOS7DefaultUserAvatar"];
    } else {
        ownMessage.avatar = image ?: [UIImage imageNamed:@"defaultUserAvatar"];
    }
    ownMessage.role = @"user";
    ownMessage.content = trimmedText;
    ownMessage.type = 1; // User message type
    ownMessage.imageHash = nil;
    ownMessage.imageAttachment = nil;
    

    if (self.attachmentImage.image != nil) {
        NSData *imageData = UIImagePNGRepresentation(self.attachmentImage.image);
        if (imageData) {
            ownMessage.imageAttachment = self.attachmentImage.image;

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *encodedImage = [imageData base64EncodedString];
                dispatch_async(dispatch_get_main_queue(), ^{
                    ownMessage.imageHash = encodedImage;
                });
            });
        }
    }
    
    float contentWidth = UIScreen.mainScreen.bounds.size.width - 63;
    CGSize textSize = [ownMessage.content sizeWithFont:[UIFont systemFontOfSize:15]
                                     constrainedToSize:CGSizeMake(contentWidth, MAXFLOAT)
                                         lineBreakMode:NSLineBreakByWordWrapping];
    ownMessage.contentHeight = textSize.height + 50;
    
    [self.messages addObject:ownMessage];
    [self.chatTableView reloadData];
    
    if (matches > 0) {
        // Route to image generation API (e.g., DALL·E)
        [CGAPICommunicator createImageGenerationWithContent:trimmedText];
    } else {
        [CGAPICommunicator createChatCompletionwithContent:self.messages];
    }
    
    self.inputField.text = @"";
    self.inputFieldPlaceholder.hidden = NO;
    [self removeAttachment];
    [self slideDownTypeView];
    self.attachmentImage.image = nil;
    
    if (self.viewingPresentTime) {
        [self.chatTableView setContentOffset:CGPointMake(0, self.chatTableView.contentSize.height - self.chatTableView.frame.size.height) animated:YES];
    }
}


- (IBAction)camera:(id)sender {
    [self.inputField resignFirstResponder];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        // iPad-specific implementation using UIPopoverController
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
            UIImagePickerController *picker = UIImagePickerController.new;
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            picker.delegate = self;
            
            // Initialize UIPopoverController
            UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:picker];
            self.imagePopoverController = popoverController;
            
            if ([sender isKindOfClass:[UIBarButtonItem class]]) {
                // Use the bar button item's view for popover presentation
                UIBarButtonItem *barButtonItem = (UIBarButtonItem *)sender;
                [popoverController presentPopoverFromBarButtonItem:barButtonItem
                                          permittedArrowDirections:UIPopoverArrowDirectionAny
                                                          animated:YES];
            }
        }
    } else {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            UIActionSheet *imageSourceActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                                delegate:self
                                                                       cancelButtonTitle:@"Cancel"
                                                                  destructiveButtonTitle:nil
                                                                       otherButtonTitles:@"Take Photo or Video", @"Choose Existing", nil];
            [imageSourceActionSheet setTag:1];
            [imageSourceActionSheet showInView:self.view];
        } else {
            // Camera is not supported, use photo library
            UIImagePickerController *picker = UIImagePickerController.new;
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            picker.delegate = self;
            
            [self presentViewController:picker animated:YES completion:nil];
        }
    }
}

- (IBAction)showSidebar:(id)sender {
    //[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [self.slideMenuController showLeftMenu:YES];

}


- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([popup tag] == 1) { // Image Source selection
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = (id)self;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        if (buttonIndex == 0) {
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            } else {
                return;
            }
        } else if (buttonIndex == 1) {
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        } else {
            return;
        }
        
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissModalViewControllerAnimated:YES];
    [self.imagePopoverController dismissPopoverAnimated:YES];
    self.imagePopoverController = nil;
    
    UIImage* originalImage = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!originalImage) originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (!originalImage) originalImage = [info objectForKey:UIImagePickerControllerCropRect];
    
    self.attachmentImage.image = originalImage;
    self.attachmentView.hidden = NO;
    [UIView animateWithDuration:0.33 animations:^{
        self.attachmentView.alpha = 1.0;
    } completion:^(BOOL finished) {
    }];
}

- (IBAction)didTapAttachment:(id)sender {
    [self.attachmentView becomeFirstResponder];

    UIMenuItem *option1 = [[UIMenuItem alloc] initWithTitle:@"View" action:@selector(viewAttachment)];
    UIMenuItem *option2 = [[UIMenuItem alloc] initWithTitle:@"Remove" action:@selector(removeAttachment)];
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    [menuController setMenuItems:@[option1, option2]];
    
    UIView *senderView = self.attachmentView;
    if (senderView.superview) {
        [menuController setTargetRect:senderView.frame inView:senderView.superview];
        [menuController setMenuVisible:YES animated:YES];
    }
}

- (void)viewAttachment {
    if(self.attachmentImage.image != nil)
        [self performSegueWithIdentifier:@"to Viewer" sender:self];
}

- (void)removeAttachment {
    [UIView animateWithDuration:0.33 animations:^{
        self.attachmentView.alpha = 0.0;
    } completion:^(BOOL finished) {
        if (finished) {
            self.attachmentView.hidden = YES;
            self.attachmentImage.image = nil;
        }
    }];
}

- (void)setCurrentConversationUniqueID:(NSString *)ConversationID {
    if(ConversationID != nil) {
        self.currentConversationID = ConversationID;
    } else {
        NSString *randomID = [[NSUUID UUID] UUIDString];
        //New conversation huh?
        self.currentConversationID = randomID;
    }
}

#pragma mark anims
- (void)slideDownTypeView {
    CGRect currentFrame = self.typeView.frame;
    CGRect finalFrame = CGRectOffset(currentFrame, 0, 30);
    [UIView animateWithDuration:0.25 animations:^{
        self.typeView.frame = finalFrame;
        
    }];
}

- (void)slideUpTypeView {
    CGRect currentFrame = self.typeView.frame;
    CGRect finalFrame = CGRectOffset(currentFrame, 0, -30);
    [UIView animateWithDuration:0.25 animations:^{
        self.typeView.frame = finalFrame;
        
    }];
}

- (void)invokeTitleChange {
    if (self.notTheAlert) {  // Prevent multiple alerts from stacking up
        return;
    }
    self.done = YES;
    int randomDelay = arc4random_uniform(16) + 15;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(randomDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.notTheAlert = YES;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Already have an idea?" message:@"Give your conversation a fitting name." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
        //input field
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alertView setTag:1];
        [alertView show];
        [self.inputField resignFirstResponder];
    });
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1) {
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            NSString *enteredText = [alertView textFieldAtIndex:0].text;
            self.navigationItem.title = enteredText;
            self.notTheAlert = NO;
            [self saveCurrentChat:nil];
            [NSNotificationCenter.defaultCenter postNotificationName:@"RE-CHECK CONVOS" object:nil];
            
        } else if(buttonIndex == alertView.cancelButtonIndex)
            self.notTheAlert = NO;
    }
}


#pragma mark tableview


- (int)countOfMessages {
    return self.messages.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rowCount = 0;
    for (CGMessage *message in self.messages) {
        rowCount++;
        if (message.imageAttachment != nil) {
            rowCount++;
        }
    }
    return rowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger messageIndex = 0;
    
    for (NSInteger i = 0; i < self.messages.count; i++) {
        CGMessage *message = self.messages[i];
        
        if (indexPath.row == messageIndex) {
            if (message.type == 2) {
                [tableView registerNib:[UINib nibWithNibName:@"CGChatTableCell" bundle:nil] forCellReuseIdentifier:@"Message Cell"];
                CGChatTableCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Message Cell"];

                [cell.authorLabel setText:message.author];

                if (VERSION_MIN(@"6.0")) {
                    [cell configureWithMessage:message.content];
                    cell.iOS7Separator.hidden = YES;
                } else {
                    [cell.contentTextView setText:message.content];
                }
                
                if(VERSION_MIN(@"7.0")) {
                    [cell.contentView setBackgroundColor:[UIColor colorWithWhite:0.96 alpha:1.0]];
                    [cell.separator setImage:nil];
                    cell.iOS7Separator.hidden = NO;
                    
                }
                
                [cell.contentTextView setHeight:[cell.contentTextView sizeThatFits:CGSizeMake(cell.contentTextView.width, MAXFLOAT)].height];
                
                [cell.avatar setImage:message.avatar];
                cell.avatar.layer.cornerRadius = cell.avatar.frame.size.width / 6.0;
                cell.avatar.layer.masksToBounds = YES;
                
                cell.separator.hidden = (indexPath.row == 0);
                return cell;
            } else if (message.type == 1) {
                [tableView registerNib:[UINib nibWithNibName:@"CGAuthorChatTableCell" bundle:nil] forCellReuseIdentifier:@"Author Cell"];
                CGAuthorTableCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Author Cell"];
                [cell.authorLabel setText:message.author];
                
                [cell.contentTextView setText:message.content];
                
                [cell.contentTextView setHeight:[cell.contentTextView sizeThatFits:CGSizeMake(cell.contentTextView.width, MAXFLOAT)].height];
                if(VERSION_MIN(@"7.0")) {
                    [cell.contentView setBackgroundColor:[UIColor colorWithWhite:0.98 alpha:1.0]];
                    
                    [cell.aOverlay setImage:[UIImage imageNamed:@"iOS7AvatarOverlay"]];
                    [cell.separator setImage:nil];
                    cell.iOS7Separator.hidden = (indexPath.row == 0);
                } else {
                    cell.iOS7Separator.hidden = YES;
                }
                
                [cell.avatar setImage:message.avatar];
                cell.aOverlay.layer.cornerRadius = cell.aOverlay.frame.size.width / 6.0;
                cell.avatar.layer.cornerRadius = cell.avatar.frame.size.width / 6.0;
                cell.avatar.layer.masksToBounds = YES;
                
                cell.separator.hidden = (indexPath.row == 0);
                return cell;
            }
        }
        
        messageIndex++; // Move to the next row
        
        
        //IMAGE THING
        if (message.imageAttachment != nil) {
            if (indexPath.row == messageIndex) {
                if(message.type == 1) {
                    [tableView registerNib:[UINib nibWithNibName:@"CGImageAttachment" bundle:nil] forCellReuseIdentifier:@"Image Cell"];
                    CGImageAttachment *imageCell = [tableView dequeueReusableCellWithIdentifier:@"Image Cell"];
                    imageCell.thumbnail.layer.cornerRadius = 10;
                    imageCell.thumbnail.layer.masksToBounds = YES;
                    imageCell.thumbnail.clipsToBounds = YES;
                    imageCell.thumbnail.contentMode = UIViewContentModeScaleAspectFill;
                    
                    if(VERSION_MIN(@"7.0")) {
                        [imageCell.thumbMask setImage:[UIImage imageNamed:@"iOS7AttachmentCellMask"]];
                    }
                    
                    [imageCell.thumbnail setImage:message.imageAttachment];
                    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedImage:)];
                    singleTap.numberOfTapsRequired = 1;
                    imageCell.totalThumbView.userInteractionEnabled = YES;
                    [imageCell.contentView setBackgroundColor:[UIColor colorWithWhite:0.98 alpha:1.0]];
                    [imageCell.totalThumbView addGestureRecognizer:singleTap];
                    return imageCell;
                } else if(message.type == 2) {
                    [tableView registerNib:[UINib nibWithNibName:@"CGAImageAttachment" bundle:nil] forCellReuseIdentifier:@"AImage Cell"];
                    CGAImageAttachment *imageCell = [tableView dequeueReusableCellWithIdentifier:@"AImage Cell"];
                    
                    
                    if(VERSION_MIN(@"7.0")) {
                        [imageCell.thumbMask setImage:[UIImage imageNamed:@"iOS7AttachmentCellMask"]];
                    }
                    imageCell.thumbnail.layer.cornerRadius = 10;
                    imageCell.thumbnail.layer.masksToBounds = YES;
                    imageCell.thumbnail.clipsToBounds = YES;
                    imageCell.thumbnail.contentMode = UIViewContentModeScaleAspectFill;
                    [imageCell.contentView setBackgroundColor:[UIColor colorWithWhite:0.96 alpha:1.0]];
                    [imageCell.thumbnail setImage:message.imageAttachment];
                    
                    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedImage:)];
                    singleTap.numberOfTapsRequired = 1;
                    imageCell.totalThumbView.userInteractionEnabled = YES;
                    
                    [imageCell.totalThumbView addGestureRecognizer:singleTap];
                    return imageCell;
                }
            }
            messageIndex++;
        }
    }
    
    return nil;
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	self.viewingPresentTime = (scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.height - 10);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger messageIndex = 0;
    
    for (CGMessage *message in self.messages) {
        if (indexPath.row == messageIndex) {
            return message.contentHeight; // Height for text messages
        }
        messageIndex++;
        
        if (message.imageAttachment != nil) {
            if (indexPath.row == messageIndex) {
                return 140; // Fixed height for images
            }
            messageIndex++;
        }
    }
    
    return 44;
}


#pragma mark keyboard
- (void)keyboardWillShow:(NSNotification *)notification {
	if(self.notTheAlert == NO) {
        int keyboardHeight = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
        float keyboardAnimationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
        int keyboardAnimationCurve = [[notification.userInfo objectForKey: UIKeyboardAnimationCurveUserInfoKey] integerValue];
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:keyboardAnimationDuration];
        [UIView setAnimationCurve:keyboardAnimationCurve];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [self.chatTableView setHeight:self.view.height - keyboardHeight - self.toolbar.height];
        [self.toolbar setY:self.view.height - keyboardHeight - self.toolbar.height];
        [UIView commitAnimations];
        
        if(self.viewingPresentTime)
            [self.chatTableView setContentOffset:CGPointMake(0, self.chatTableView.contentSize.height - self.chatTableView.frame.size.height) animated:NO];
    }
}


- (void)keyboardWillHide:(NSNotification *)notification {
	
	float keyboardAnimationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
	int keyboardAnimationCurve = [[notification.userInfo objectForKey: UIKeyboardAnimationCurveUserInfoKey] integerValue];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:keyboardAnimationDuration];
	[UIView setAnimationCurve:keyboardAnimationCurve];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[self.chatTableView setHeight:self.view.height - self.toolbar.height];
	[self.toolbar setY:self.view.height - self.toolbar.height];
	[UIView commitAnimations];
}


//Log
- (BOOL) textViewShouldBeginEditing:(UITextView *)textView {
    self.inputFieldPlaceholder.hidden = self.inputField.text.length != 0;
    return YES;
}

-(void) textViewDidChange:(UITextView *)textView {
    self.inputFieldPlaceholder.hidden = self.inputField.text.length != 0;
}

-(void) textViewDidEndEditing:(UITextView *)textView {
    self.inputFieldPlaceholder.hidden = self.inputField.text.length != 0;
}

//Segues
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"to Viewer"]){
		CGImageViewController *imageViewController = [segue destinationViewController];
		UIImage *selectedImage = self.attachmentImage.image;
        
        if(self.selectedImage != nil) {
            selectedImage = self.selectedImage;
        }
		if ([imageViewController isKindOfClass:CGImageViewController.class]){
			dispatch_async(dispatch_get_main_queue(), ^{
				[imageViewController.imageView setImage:selectedImage];
                self.selectedImage = nil;
			});
		}
	}
}


- (void)checkAPICredentials {
    if(apiKey == nil) {
        [CGAPIHelper alert:@"Warning" withMessage:@"Your API Key is missing, please double-check the settings pane and make sure you've inputted an OpenAI API Key."];
    } else if([apiKey isEqual:@""]) {
        [CGAPIHelper alert:@"Warning" withMessage:@"Your API Key is missing, please double-check the settings pane and make sure you've inputted an OpenAI API Key."];
    } else {
        [CGAPIHelper checkForAPIKeyValidity];
    }
}
@end

