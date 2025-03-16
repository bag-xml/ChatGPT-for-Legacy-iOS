//
//  CGWelcomeController.h
//  ChatGPT
//
//  Created by XML on 27/02/25.
//  Copyright (c) 2025 XML. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CGAPIHelper.h"

@interface CGWelcomeController : UIViewController <UITableViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UINavigationBar *navBar;
@property bool authenticated;
@property (weak, nonatomic) IBOutlet UIView *slideLabel;
@property (weak, nonatomic) IBOutlet UIView *slideicon;
@property (weak, nonatomic) IBOutlet UIView *WLBoxView;


@property (weak, nonatomic) IBOutlet UIView *SCThumbnailView;
@property (weak, nonatomic) IBOutlet UIView *CONVThumbnailView;
@property (weak, nonatomic) IBOutlet UIView *pickThumbnailView;
@property (weak, nonatomic) IBOutlet UITextField *KeyInputField;
@end
