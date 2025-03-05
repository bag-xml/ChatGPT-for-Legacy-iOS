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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return (section == 0) ? 0 : 28.0; // Remove header space for "New Chat", keep 40.0 for "Conversations"
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return nil; // No header for "New Chat" section
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
        NSLog(@"User tapped on 'New Chat' cell.");
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
