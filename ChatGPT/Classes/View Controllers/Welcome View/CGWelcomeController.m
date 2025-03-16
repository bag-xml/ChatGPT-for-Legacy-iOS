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

- (void)viewWillAppear:(BOOL)animated {
    NSDictionary *titleTextAttributes = @{
                                          UITextAttributeTextColor: [UIColor colorWithRed:74/255.0 green:125/255.0 blue:112/255.0 alpha:1.0],
                                          UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
                                          UITextAttributeTextShadowColor: [UIColor whiteColor]
                                          };
    [self.navBar setTitleTextAttributes:titleTextAttributes];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.authenticated = NO;
    self.WLBoxView.alpha = 0.0;
    self.KeyInputField.delegate = self;
    [self.navBar setBackgroundImage:[UIImage imageNamed:@"bar-BG"] forBarMetrics:UIBarMetricsDefault];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(endOOBE:) name:@"LOG-IN VALID" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(abruptFailure:) name:@"LOG-IN FAILURE" object:nil];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self bringIntroductionInShape];
}
- (void)bringIntroductionInShape {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CGRect SiCurrentFrame = self.slideicon.frame;
        CGRect SiFinalFrame = CGRectOffset(SiCurrentFrame, -60, 0);
        
        CGRect SLCurrentFrame = self.slideLabel.frame;
        CGRect SLFinalFrame = CGRectOffset(SLCurrentFrame, 130, 0);
        [UIView animateWithDuration:0.75 animations:^{
            self.WLBoxView.alpha = 1.0;
            self.slideicon.frame = SiFinalFrame;
            self.slideLabel.frame = SLFinalFrame;
        }];
    });
    CABasicAnimation *rocking = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rocking.fromValue = @(-M_PI / 16);
    rocking.toValue = @(M_PI / 16);
    rocking.duration = 1.5;
    rocking.autoreverses = YES;
    rocking.repeatCount = INFINITY;
    rocking.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]; // Smooth motion
    
    [self.SCThumbnailView.layer addAnimation:rocking forKey:@"rockingAnimation"];
    [self.CONVThumbnailView.layer addAnimation:rocking forKey:@"rockingAnimation"];
    [self.pickThumbnailView.layer addAnimation:rocking forKey:@"rockingAnimation"];
}

//hmm

- (void)endOOBE:(NSNotification *)notification {
    [SVProgressHUD dismiss];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstLaunch"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissModalViewControllerAnimated:YES];
        NSString *statusMessage = [NSString stringWithFormat:@"Logged in as %@.",[[NSUserDefaults standardUserDefaults] objectForKey:@"username"]];
        [SVProgressHUD showSuccessWithStatus:statusMessage];
    });
}

- (void)abruptFailure:(NSNotification *)notification {
    [SVProgressHUD dismiss];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [SVProgressHUD showErrorWithStatus:@"An error occured. Please retry."];
    });
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    // Perform actions when the return key is pressed, like resigning the first responder status
    [self.KeyInputField resignFirstResponder];  // Dismiss the keyboard
    [SVProgressHUD showWithStatus:@"Logging in..." maskType:SVProgressHUDMaskTypeGradient];
    [CGAPIHelper logInUserwithKey:self.KeyInputField.text];
    return YES;
}





@end
