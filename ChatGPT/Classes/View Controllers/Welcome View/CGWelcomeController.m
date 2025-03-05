//
//  CGWelcomeController.m
//  ChatGPT
//
//  Created by XML on 27/02/25.
//  Copyright (c) 2025 XML. All rights reserved.
//

#import "CGWelcomeController.h"

@interface CGWelcomeController ()

@end

@implementation CGWelcomeController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (IBAction)iNeedToPlayUC4:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstLaunch"];
}

@end
