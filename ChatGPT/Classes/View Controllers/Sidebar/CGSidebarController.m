//
//  CGSidebarController.m
//  ChatGPT
//
//  Created by XML on 23/02/25.
//  Copyright (c) 2025 XML. All rights reserved.
//

#import "CGSidebarController.h"

@interface CGSidebarController ()

@end

@implementation CGSidebarController

- (void)viewDidLoad {
    [super viewDidLoad];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(recheckandReload:) name:@"RE-CHECK CONVOS" object:nil];
    self.allConversations = [CGAPIHelper loadConversations];
    
    [self.tableView reloadData];

}

- (void)recheckandReload:(NSNotification *)notification {
    self.allConversations = nil;
    self.allConversations = [CGAPIHelper loadConversations];
    [self.tableView reloadData];
}

- (IBAction)didLongPressCell:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        CGPoint location = [sender locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
        
        if (indexPath.section == 1 && self.allConversations.count > 0) {
            self.selectedIndexPath = indexPath;
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Quick action panel" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Rename", @"Share", @"Delete", nil];
            //input field
            [alertView setTag:1];
            [alertView show];
        } else if(indexPath.section == 0) {
            UINavigationController *navigationController = (UINavigationController *)self.slideMenuController.contentViewController;
            CGChatViewController *contentViewController = navigationController.viewControllers.firstObject;
            int curMes = [contentViewController countOfMessages];
            NSLog(@"%i penis", curMes);
            if(self.allConversations.count < 1) {
                if([contentViewController countOfMessages] < 1) {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Quick action panel" message:@"You don't have any conversations yet, you should chat more and save this conversation!" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
                    //input field
                    [alertView setTag:3];
                    [alertView show];
                } else {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Quick action panel" message:@"Save your conversation now" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
                    //input field
                    [alertView setTag:3];
                    [alertView show];
                }
            } else if(self.allConversations.count > 0) {
                if([contentViewController countOfMessages] < 1) {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Quick action panel" message:@"You need to start sending messages in order to be able to save your conversations." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete all conversations", nil];
                    //input field
                    [alertView setTag:4];
                    [alertView show];
                } else {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Quick action panel" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save conversation", @"Delete all conversations", nil];
                    //input field
                    [alertView setTag:3];
                    [alertView show];
                }
            }
            
            
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(alertView.tag == 1) {
        if (buttonIndex == 1) {  // "Option 1"
            CGConversation *currentConv = self.allConversations[self.selectedIndexPath.row];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Rename Conversation" message:@"Once you're done, press the 'Done' button." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
            //input field
            alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            
            UITextField *textField = [alertView textFieldAtIndex:0];
            textField.text = currentConv.title;
            
            [alertView setTag:2];
            [alertView show];
        } else if (buttonIndex == 2) {  // "Option 2"
            [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                CGConversation *currentConv = self.allConversations[self.selectedIndexPath.row];
                NSMutableArray *dict = currentConv.messages;
                NSMutableArray *messages = [[NSMutableArray alloc] init];
                for (CGMessage *message in dict) {
                    NSString *messgae = [NSString stringWithFormat:@"%@: %@", message.author, message.content];
                    [messages addObject:messgae];
                }
                NSString *jumbotron = [NSString stringWithFormat:@"%@, created at %@, with the following messages:\n\n %@ \n\n Made with ChatGPT for Legacy iOS", currentConv.title, currentConv.creationDate, messages];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.slideMenuController showShareSheet:jumbotron];
                    //need the message property now, ill create a text file that way.
                });
            });
        } else if (buttonIndex == 3) {  // "Delete"
            CGConversation *selectedConv = self.allConversations[self.selectedIndexPath.row];
            BOOL success = [CGAPIHelper deleteConversationWithUUID:selectedConv.uuid];
            if (success) {
                self.selectedIndexPath = nil;
                [NSNotificationCenter.defaultCenter postNotificationName:@"RE-CHECK CONVOS" object:nil];
            }

            
        }
    } else if(alertView.tag == 2) {
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            NSString *enteredText = [alertView textFieldAtIndex:0].text;
            CGConversation *selectedConv = self.allConversations[self.selectedIndexPath.row];
            UINavigationController *navigationController = (UINavigationController *)self.slideMenuController.contentViewController;
            CGChatViewController *contentViewController = navigationController.viewControllers.firstObject;
            [contentViewController setTitle:enteredText];
            [CGAPIHelper saveConversationWithArray:selectedConv.messages withID:selectedConv.uuid withTitle:enteredText]; //should overwrite the other uuid post, so its always uptodate
            [NSNotificationCenter.defaultCenter postNotificationName:@"RE-CHECK CONVOS" object:nil];
            self.selectedIndexPath = nil;
        }
    } else if(alertView.tag == 3) {
        if(buttonIndex == 1) {
            [NSNotificationCenter.defaultCenter postNotificationName:@"SAVE CHAT" object:nil];
            [self recheckandReload:nil];
        } else if(buttonIndex == 2) {
            NSLog(@"2");
            BOOL success = [CGAPIHelper deleteAllConversations];
            if(success) {
                [NSNotificationCenter.defaultCenter postNotificationName:@"RE-CHECK CONVOS" object:nil];
            }
        }
    } else if(alertView.tag == 4) {
        if(buttonIndex == 1) {
            BOOL success = [CGAPIHelper deleteAllConversations];
            if(success) {
                [NSNotificationCenter.defaultCenter postNotificationName:@"RE-CHECK CONVOS" object:nil];
            }
        }
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return (section == 0) ? 0 : 28.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return nil;
    }
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 28)];
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:headerView.bounds];
    backgroundImageView.contentMode = UIViewContentModeScaleToFill;

    backgroundImageView.image = [UIImage imageNamed:@"headerSeparator"];
    [headerView addSubview:backgroundImageView];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, tableView.frame.size.width - 20, 18)];
    label.textColor = [UIColor colorWithRed:158.0/255.0 green:159.0/255.0 blue:159.0/255.0 alpha:1.0];
    label.layer.shadowColor = [UIColor blackColor].CGColor;
    label.layer.shadowOffset = CGSizeMake(0, 1);
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:16];
    
    if (section == 1) {
        label.text = @"Chats";
    }
    
    [headerView addSubview:label];
    return headerView;
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        if (self.allConversations.count == 0)
            return 1;
        return self.allConversations.count;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 57.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        if (self.allConversations.count == 0) {
            // Display "Nothing" Cell when no conversations exist
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Nothing"];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Nothing"];
            }

            return cell;
        } else if(self.allConversations.count > 0) {
            // Display conversations in "ConvoCell"
            CGConversation *conversation = self.allConversations[indexPath.row];
            CGConversationElementCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ConvoCell"];
            if (cell == nil) {
                cell = [[CGConversationElementCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ConvoCell"];
            }
            
            cell.conversationName.text = conversation.title;
            if (conversation.messageCount < 2) {
                cell.accessoryLabel.text = [NSString stringWithFormat:@"%i message, created on %@", conversation.messageCount, conversation.creationDate];
            } else {
                cell.accessoryLabel.text = [NSString stringWithFormat:@"%i messages, created on %@", conversation.messageCount, conversation.creationDate];
            }
            
            return cell;
        }
    } else if (indexPath.section == 0) {
        // Display "New Chat" Cell
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NewChat"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NewChat"];
        }

        return cell;
    }
    
    return nil;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        UINavigationController *navigationController = (UINavigationController *)self.slideMenuController.contentViewController;
        CGChatViewController *contentViewController = navigationController.viewControllers.firstObject;
        if ([contentViewController isKindOfClass:[CGChatViewController class]]) {
            
            [contentViewController.navigationItem setTitle:@"Chat"];
            [contentViewController startNewConversation];
            [contentViewController setViewingPresentTime:true];
            [self.slideMenuController hideMenu:YES];
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    if(self.allConversations.count == 0)
        return;
    
    CGConversation *conversation = self.allConversations[indexPath.row];
    UINavigationController *navigationController = (UINavigationController *)self.slideMenuController.contentViewController;
    CGChatViewController *contentViewController = navigationController.viewControllers.firstObject;
    if ([contentViewController isKindOfClass:[CGChatViewController class]]) {
        
        [contentViewController.navigationItem setTitle:conversation.title];
        [contentViewController loadChat:conversation.messages withUUID:conversation.uuid];
        [contentViewController setViewingPresentTime:true];
        [self.slideMenuController hideMenu:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
