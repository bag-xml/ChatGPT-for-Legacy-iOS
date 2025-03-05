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
    NSDictionary *titleTextAttributes = @{
                                          UITextAttributeTextColor: [UIColor colorWithRed:74/255.0 green:125/255.0 blue:112/255.0 alpha:1.0],
                                          UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
                                          UITextAttributeTextShadowColor: [UIColor whiteColor]
                                          };
    [self.navigationController.navigationBar setTitleTextAttributes:titleTextAttributes];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleAIResponse:) name:@"AI RESPONSE" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(saveCurrentChat:) name:@"SAVE CHAT" object:nil];
    self.slideMenuController.bouncing = YES;
    self.slideMenuController.gestureSupport = APLSlideMenuGestureSupportDrag;
    self.slideMenuController.separatorColor = [UIColor grayColor];
    
    self.chatTableView.delegate = self;
    self.chatTableView.dataSource = self;
    self.messages = [NSMutableArray array];
    
    bool firstLaunch = [[NSUserDefaults standardUserDefaults] boolForKey:@"firstLaunch"];
    if(firstLaunch == NO)
        [self prepareFirstLaunch];
    
    self.attachmentView.hidden = YES;
    self.attachmentImage.image = nil;
    self.attachmentImage.layer.cornerRadius = self.attachmentImage.frame.size.width / 8.0;
    self.attachmentImage.layer.masksToBounds = YES;
    
    if(self.currentConversationID == nil) {
        [self setCurrentConversationUniqueID:nil];
    }

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
    [self.inputField setDelegate:self];
    [[self.inputView layer] setMasksToBounds:YES];
    [[self.inputView layer] setCornerRadius:14.5f];
    self.inputFieldPlaceholder.hidden = NO;
}

- (void)handleAIResponse:(NSNotification *)notification {
    CGMessage *Response = notification.object;
    [self.messages addObject:Response];
    [self slideUpTypeView];
    [self.chatTableView reloadData];
    if(self.viewingPresentTime)
        [self.chatTableView setContentOffset:CGPointMake(0, self.chatTableView.contentSize.height - self.chatTableView.frame.size.height) animated:YES];
    
    if (self.messages.count >= 7 && self.messages.count <= 17) {
        if(self.done == NO)
            [self invokeTitleChange];
    }

}

- (void)saveCurrentChat:(NSNotification *)notification {
    if (self.messages.count > 0) {
        [CGAPIHelper saveConversationWithArray:self.messages withID:self.currentConversationID withTitle:self.navigationItem.title];
    }
}

- (void)prepareFirstLaunch {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"Ass");
        [self performSegueWithIdentifier:@"welcome" sender:self];
    });
}
- (void)loadChat:(NSMutableArray *)messages withUUID:(NSString *)uuid {
    self.messages = nil;
    self.messages = messages;
    if(messages.count < 6)
        self.done = NO;
    [self setCurrentConversationUniqueID:uuid];
    [self.chatTableView reloadData];
}

- (void)startNewConversation {
    [self slideUpTypeView];
    [self setCurrentConversationUniqueID:nil];
    self.messages = NSMutableArray.new;
    [self.chatTableView reloadData];
    self.done = NO;
}

- (IBAction)send:(id)sender {
    if (self.attachmentImage.image != nil) {
        NSData *imageData = UIImagePNGRepresentation(self.attachmentImage.image);
        if (imageData) {
            //Create the user's message
            CGMessage *ownMessage = CGMessage.new;
            ownMessage.author = @"You";
            ownMessage.avatar = [UIImage imageNamed:@"missingAvatar"];
            ownMessage.role = @"user";
            ownMessage.content = self.inputField.text;
            ownMessage.type = 1; // User message type
            
            float contentWidth = UIScreen.mainScreen.bounds.size.width - 63;
            CGSize textSize = [ownMessage.content sizeWithFont:[UIFont systemFontOfSize:15]
                                             constrainedToSize:CGSizeMake(contentWidth, MAXFLOAT)
                                                 lineBreakMode:NSLineBreakByWordWrapping];
            ownMessage.contentHeight = textSize.height + 50;
            
            NSString *encodedImage = [imageData base64EncodedString];
            ownMessage.imageHash = encodedImage;
            
            [self.messages addObject:ownMessage];
            [self.chatTableView reloadData];
            
            [self slideDownTypeView];
            [CGAPICommunicator createChatCompletionwithContent:self.messages];
            self.inputField.text = @"";
            self.inputFieldPlaceholder.hidden = NO;
        }
        
        [self removeAttachment];
        self.attachmentImage.image = nil;
    } else {
        if ([self.inputField.text length] > 0 && [self.inputField.text length] < 3) {
            [CGAPIHelper alert:@"Too short" withMessage:@"For the sake of preserving your API Credit you should ask the AI questions that are longer than just three characters."];
        } else if([self.inputField.text length] > 3) {
            
            //Create the user's message
            CGMessage *ownMessage = CGMessage.new;
            //Nickname soon
            ownMessage.author = @"You";
            //also the PFP soon
            ownMessage.avatar = [UIImage imageNamed:@"missingAvatar"];
            
            
            ownMessage.role = @"user";
            ownMessage.content = self.inputField.text;
            ownMessage.type = 1; //User message type
            ownMessage.imageHash = nil;
            
            
            float contentWidth = UIScreen.mainScreen.bounds.size.width - 63;
            CGSize textSize = [ownMessage.content sizeWithFont:[UIFont systemFontOfSize:15] constrainedToSize:CGSizeMake(contentWidth, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping];
            ownMessage.contentHeight = textSize.height + 50;
            
            [self.messages addObject:ownMessage];
            [self.chatTableView reloadData];
            
            [self slideDownTypeView];
            [CGAPICommunicator createChatCompletionwithContent:self.messages];
            self.inputField.text = @"";
            self.inputFieldPlaceholder.hidden = NO;
            
        } else if([self.inputField.text length] < 1) {
            [self.inputField resignFirstResponder];
            
        }
    }
    
    if(self.viewingPresentTime)
        [self.chatTableView setContentOffset:CGPointMake(0, self.chatTableView.contentSize.height - self.chatTableView.frame.size.height) animated:YES];
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
        }
    }];
    self.attachmentImage.image = nil;
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
    self.done = YES;
    int randomDelay = arc4random_uniform(16) + 15;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(randomDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"Invocation2");
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
            [self saveCurrentChat:nil];
            [NSNotificationCenter.defaultCenter postNotificationName:@"RE-CHECK CONVOS" object:nil];
            
        }
    }
}


#pragma mark tableview

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGMessage *message = self.messages[indexPath.row];
    
    if(message.type == 2) {
        [tableView registerNib:[UINib nibWithNibName:@"CGChatTableCell" bundle:nil] forCellReuseIdentifier:@"Message Cell"];
        CGChatTableCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Message Cell"];
        
        
        [cell.authorLabel setText:message.author];
        
        [cell.contentTextView setText:message.content];
        
        [cell.contentTextView setHeight:[cell.contentTextView sizeThatFits:CGSizeMake(cell.contentTextView.width, MAXFLOAT)].height];
        
        [cell.avatar setImage:message.avatar];
        cell.avatar.layer.cornerRadius = cell.avatar.frame.size.width / 7.0;
        cell.avatar.layer.masksToBounds = YES;
        
        if (indexPath.row == 0) {
            cell.separator.hidden = YES;
        } else {
            cell.separator.hidden = NO;
        }
        return cell;
    } else if(message.type == 1) {
        [tableView registerNib:[UINib nibWithNibName:@"CGAuthorChatTableCell" bundle:nil] forCellReuseIdentifier:@"Author Cell"];
        CGAuthorTableCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Author Cell"];
        
        
        [cell.authorLabel setText:message.author];
        [cell.contentTextView setText:message.content];
        
        [cell.contentTextView setHeight:[cell.contentTextView sizeThatFits:CGSizeMake(cell.contentTextView.width, MAXFLOAT)].height];
        
        [cell.avatar setImage:message.avatar];
        cell.avatar.layer.cornerRadius = cell.avatar.frame.size.width / 8.0;
        cell.avatar.layer.masksToBounds = YES;
        
        if (indexPath.row == 0) {
            cell.separator.hidden = YES;
        } else {
            cell.separator.hidden = NO;
        }

        
        return cell;
    }
    return nil;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	self.viewingPresentTime = (scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.height - 10);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	CGMessage* messageAtRowIndex = [self.messages objectAtIndex:indexPath.row];
	return messageAtRowIndex.contentHeight;
}


#pragma mark keyboard
- (void)keyboardWillShow:(NSNotification *)notification {
	
	//thx to Pierre Legrain
	//http://pyl.io/2015/08/17/animating-in-sync-with-ios-keyboard/
	
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
		if ([imageViewController isKindOfClass:CGImageViewController.class]){
			dispatch_async(dispatch_get_main_queue(), ^{
				[imageViewController.imageView setImage:selectedImage];
			});
		}
	}
}
@end

