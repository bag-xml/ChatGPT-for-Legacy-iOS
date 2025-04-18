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

@property bool authenticated;

@property (weak, nonatomic) IBOutlet UIView *slideLabel; //IMPv2
@property (weak, nonatomic) IBOutlet UIView *slideicon; //IMP
@property (weak, nonatomic) IBOutlet UIImageView *realWELSlideIcon;
@property (weak, nonatomic) IBOutlet UILabel *realWELSlideLabel;

@property (weak, nonatomic) IBOutlet UIView *WLBoxView;

//mvp
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UIView *secondaryView1;
@property (weak, nonatomic) IBOutlet UIView *secondaryView2;
@property (weak, nonatomic) IBOutlet UIView *secondaryView3;

//Other
@property (weak, nonatomic) IBOutlet UILabel *head1;
@property (weak, nonatomic) IBOutlet UILabel *head2;
@property (weak, nonatomic) IBOutlet UILabel *head3;
@property (weak, nonatomic) IBOutlet UILabel *head4;
@property (weak, nonatomic) IBOutlet UIImageView *inputFieldBackground;
@property (weak, nonatomic) IBOutlet UIImageView *separator1;
@property (weak, nonatomic) IBOutlet UIImageView *i7sep1;
@property (weak, nonatomic) IBOutlet UIImageView *i7sep2;
@property (weak, nonatomic) IBOutlet UIImageView *separator2;
@property (weak, nonatomic) IBOutlet UIImageView *i7sep3;
@property (weak, nonatomic) IBOutlet UIImageView *separator3;
@property (weak, nonatomic) IBOutlet UIImageView *separator4;
@property (weak, nonatomic) IBOutlet UIImageView *i7sep4;

@property (weak, nonatomic) IBOutlet UIImageView *SCTImage;

@property (weak, nonatomic) IBOutlet UIView *SCThumbnailView;
@property (weak, nonatomic) IBOutlet UIView *CONVThumbnailView;
@property (weak, nonatomic) IBOutlet UIView *pickThumbnailView;
@property (weak, nonatomic) IBOutlet UITextView *versatileTextView;
@property (weak, nonatomic) IBOutlet UITextField *KeyInputField;
@end
