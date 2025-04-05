//
//  CGImageViewController.m
//  ChatGPT
//
//  Created by XML on 22/02/25.
//  Copyright (c) 2025 XML. All rights reserved.
//

#import "CGImageViewController.h"

@interface CGImageViewController ()

@end

@implementation CGImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *clearImage = [UIImage new]; // Blank image
    [self.navigationController.navigationBar setBackgroundImage:clearImage forBarMetrics:UIBarMetricsDefault];

}

- (void)viewDidUnload {
	[self setImageView:nil];
    [self setScrollView:nil];
	[super viewDidUnload];
}

- (IBAction)done:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

@end
