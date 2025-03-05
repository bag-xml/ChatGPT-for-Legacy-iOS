//  Created by Kay J. on 4.4.14.
//  Copyright (c) 2012 apploft GmbH. All rights reserved.
//

#import "APLSlideMenuSegue.h"
#import "APLSlideMenuViewController.h"

@implementation APLSlideMenuLeftMenuSegue

- (void)perform {
    APLSlideMenuViewController* slideMenuViewController = self.sourceViewController;
    UIViewController* leftMenuViewController = self.destinationViewController;
    
    slideMenuViewController.leftMenuViewController = leftMenuViewController;
}

@end


@implementation APLSlideMenuRightMenuSegue

- (void)perform {
    APLSlideMenuViewController* slideMenuViewController = self.sourceViewController;
    UIViewController* rightMenuViewController = self.destinationViewController;
    
    slideMenuViewController.rightMenuViewController = rightMenuViewController;
}

@end


@implementation APLSlideMenuContentSegue

- (void)perform {
    APLSlideMenuViewController* slideMenuViewController = self.sourceViewController;
    UIViewController* contentViewController = self.destinationViewController;
    
    slideMenuViewController.contentViewController = contentViewController;
}


@end