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


- (void)viewDidLoad{
	[super viewDidLoad];

    self.scrollView.delegate = self;
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.maximumZoomScale = 4.0;
    self.scrollView.zoomScale = 1.0;
    
    UIImage *clearImage = [UIImage new]; // Blank image
    [self.navigationController.navigationBar setBackgroundImage:clearImage forBarMetrics:UIBarMetricsDefault];

    
}
-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
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
