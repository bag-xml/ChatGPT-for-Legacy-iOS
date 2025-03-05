//  Created by Tobias Conradi on 18.12.12.
//  Copyright (c) 2012 apploft GmbH. All rights reserved.
//

#import "APLSlideMenuViewController.h"

@implementation UIView(APLSlideMenuViewController)

- (UIView *)APLSlideMenuViewController_findSubviewOfClass:(Class)class
{
    if ([self isKindOfClass:class])
        return self;
    for (UIView *view in self.subviews)
    {
        UIView *foundSubview = [view APLSlideMenuViewController_findSubviewOfClass:class];
        if (foundSubview)
            return foundSubview;
    }
    return 0;
}

@end

NSString *APLSlideMenuWillShowNotification = @"APLSlideMenuWillShowNotificationInternal";
NSString *APLSlideMenuDidShowNotification = @"APLSlideMenuDidShowNotificationInternal";
NSString *APLSlideMenuWillHideNotification = @"APLSlideMenuWillHideNotificationInternal";
NSString *APLSlideMenuDidHideNotification = @"APLSlideMenuDidHideNotificationInternal";


static NSTimeInterval kAPLSlideMenuDefaultAnimationDuration = 0.25;
static CGFloat kAPLSlideMenuDefaultMenuWidth = 260.0;
static NSTimeInterval kAPLSlideMenuDefaultBounceDuration = 0.2;
static CGFloat kAPLSlideMenuFirstOffset = 4.0;


@interface APLSlideMenuViewController() <UIGestureRecognizerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UIGestureRecognizer *dragGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *hideTapGestureRecognizer;
@property (nonatomic, assign) CGFloat dragContentStartX;
@property (nonatomic, assign) CGPoint dragGestureStartPoint;
@property (nonatomic, assign) BOOL keyboardVisible;
@property (nonatomic, assign, getter = isMenuViewVisible) BOOL menuViewVisible;
@property (nonatomic, assign) UIView *contentContainerView;
@property (nonatomic, assign, getter = isDisplayMenuSideBySide) BOOL displayMenuSideBySide;
@property (nonatomic, strong, readwrite) UIViewController *activeMenuViewController;
@property (nonatomic, strong) UIView *leftSeparatorView;
@property (nonatomic, strong) UIView *rightSeparatorView;

@end


@implementation APLSlideMenuViewController

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
}

- (void) commonInit {
    _animationDuration  = kAPLSlideMenuDefaultAnimationDuration;
    _menuWidth          = kAPLSlideMenuDefaultMenuWidth;
    self.gestureSupport = APLSlideMenuGestureSupportBasic;
    
    _keyboardVisible    = NO;
    _bouncing           = NO;
    _tapOnContentViewToHideMenu = YES;
    self.useShadow = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
}

- (id) init {
    self = [super init];
    
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Create GestureRecognizers for NavigationView
    UIPanGestureRecognizer *panGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragGestureRecognizerDrag:)];
    panGR.delegate = self;
    panGR.minimumNumberOfTouches = 1;
    panGR.maximumNumberOfTouches = 1;
    self.dragGestureRecognizer = panGR;
    [self.view addGestureRecognizer:panGR];
    
    UIView *contentContainer = [[UIView alloc] initWithFrame:self.view.bounds];
    contentContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.contentContainerView = contentContainer;
    [self.view addSubview:contentContainer];
    [self addShadowToView:contentContainer];
    
    self.leftSeparatorView = [[UIView alloc] initWithFrame:CGRectMake(0., 0., 1., self.view.bounds.size.height)];
    self.leftSeparatorView.backgroundColor = self.separatorColor;
    self.leftSeparatorView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
    self.leftSeparatorView.hidden = YES;
    [contentContainer addSubview:self.leftSeparatorView];
    
    self.rightSeparatorView = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 1., 0., 1., self.view.bounds.size.height)];
    self.rightSeparatorView.backgroundColor = self.separatorColor;
    self.rightSeparatorView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
    self.rightSeparatorView.hidden = YES;
    [contentContainer addSubview:self.rightSeparatorView];
    
    // Set left menu, right menu, and content view controller via story board.
    @try {
        [self performSegueWithIdentifier:@"content" sender:self];
    }
    @catch (NSException *exception) {
    }
    @try {
        [self performSegueWithIdentifier:@"leftMenu" sender:self];
    }
    @catch (NSException *exception) {
    }
    @try {
        [self performSegueWithIdentifier:@"rightMenu" sender:self];
    }
    @catch (NSException *exception) {
    }
}

- (void)viewWillAppear:(BOOL)animated  {
    [super viewWillAppear:animated];
    
    [self updateShadowPath];
    if (!self.presentedViewController) {
        [self displayMenuSideBySideIfNeededForOrientation:[UIApplication sharedApplication].statusBarOrientation];
    }

}

- (void)showShareSheet:(NSString *)textContent {
    NSArray *itemsToShare = @[textContent];
	UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
	[activityVC viewWillAppear:YES];
    [self presentViewController:activityVC animated:YES completion:nil];
    [activityVC viewWillAppear:YES];
}
- (void)updateShadowPath {
    // Correct shadow size
    UIView *currentView = self.contentContainerView;
    currentView.layer.shadowPath = [UIBezierPath bezierPathWithRect:currentView.bounds].CGPath;
}

#pragma mark - Interface rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (self.contentViewController != nil) ? [[self getTopContentViewController] shouldAutorotateToInterfaceOrientation:toInterfaceOrientation] : YES;
}

- (BOOL)shouldAutorotate {
    return (self.contentViewController != nil) ? [[self getTopContentViewController] shouldAutorotate] : YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return (self.contentViewController != nil) ? [[self getTopContentViewController] supportedInterfaceOrientations] : UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView animateWithDuration:duration animations:^{
        [self displayMenuSideBySideIfNeededForOrientation:toInterfaceOrientation];
    }];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self updateShadowPath];
}

- (void)displayMenuSideBySideIfNeededForOrientation:(UIInterfaceOrientation)orientation {
    BOOL displayMenuSideBySide = (self.isShowLeftMenuInLandscape || self.isShowRightMenuInLandscape) && (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) && UIInterfaceOrientationIsLandscape(orientation);
    
    CGFloat offsetLeft = displayMenuSideBySide && self.isShowLeftMenuInLandscape ? [self menuAbsoluteWidth] : 0.;
    CGFloat offsetRight = displayMenuSideBySide && self.isShowRightMenuInLandscape ? [self menuAbsoluteWidth] : 0.;
    CGRect frame = self.contentContainerView.frame;
    frame.origin.x = offsetLeft;
    frame.size.width = self.view.bounds.size.width - offsetLeft - offsetRight;
    self.contentContainerView.frame = frame;
    self.leftSeparatorView.hidden = !(displayMenuSideBySide && self.isShowLeftMenuInLandscape);
    self.rightSeparatorView.hidden = !(displayMenuSideBySide && self.isShowRightMenuInLandscape);
    
    self.contentContainerView.clipsToBounds = displayMenuSideBySide || !self.useShadow;
    self.displayMenuSideBySide = displayMenuSideBySide;
    self.leftMenuViewController.view.accessibilityElementsHidden = !displayMenuSideBySide || !self.isShowLeftMenuInLandscape;
    self.rightMenuViewController.view.accessibilityElementsHidden = !displayMenuSideBySide || !self.isShowRightMenuInLandscape;
}

#pragma mark - status bar style

- (UIViewController*)childViewControllerForStatusBarStyle {
    return self.isMenuViewVisible ? self.activeMenuViewController : self.contentViewController;
}

#pragma mark - Properties

-(void)setMenuViewVisible:(BOOL)menuViewVisible {
    _menuViewVisible = menuViewVisible;
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (CGFloat)menuAbsoluteWidth {
    return (self.menuWidth >= 0.0 && self.menuWidth <= 1.0) ? roundf(self.menuWidth * self.view.bounds.size.width) : self.menuWidth;
}

- (UITapGestureRecognizer*)hideTapGestureRecognizer {
    if (_hideTapGestureRecognizer == nil) {
        _hideTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeTapGestureRecognizerFired:)];
        _hideTapGestureRecognizer.delegate = self;
        _hideTapGestureRecognizer.delaysTouchesBegan = YES;
        _hideTapGestureRecognizer.delaysTouchesEnded = YES;
    }
    return _hideTapGestureRecognizer;
}

- (void)setContentViewController:(UIViewController *)contentViewController {
    [self setContentViewController:contentViewController animated:NO];
}

- (void)setSettingsViewController:(UIViewController *)settingsViewController {
    [self setContentViewController:settingsViewController animated:NO];
}

- (void)setMenuViewController:(UIViewController *)menuViewController {
    [self setLeftMenuViewController:menuViewController];
}

- (UIViewController *)menuViewController {
    return self.leftMenuViewController;
}

- (void)setLeftMenuViewController:(UIViewController *)menuViewController {
    
    if (_leftMenuViewController) {
        [_leftMenuViewController willMoveToParentViewController:nil];
        [_leftMenuViewController.view removeFromSuperview];
        [_leftMenuViewController removeFromParentViewController];
    }
    
    _leftMenuViewController = menuViewController;
    if (menuViewController) {
        UIView *menuView    = menuViewController.view;
        menuView.accessibilityElementsHidden = YES;
        CGRect menuFrame = self.view.bounds;
        menuFrame.size.width = self.menuAbsoluteWidth + kAPLSlideMenuFirstOffset;
        
        menuView.frame = menuFrame;
        menuView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        
        [self addChildViewController:menuViewController];
        [self.view insertSubview:menuView atIndex:0];
        
        [menuViewController didMoveToParentViewController:self];
    }
}

- (void)setRightMenuViewController:(UIViewController *)menuViewController {
    
    if (_rightMenuViewController) {
        [_rightMenuViewController willMoveToParentViewController:nil];
        [_rightMenuViewController.view removeFromSuperview];
        [_rightMenuViewController removeFromParentViewController];
    }
    
    _rightMenuViewController = menuViewController;
    if (menuViewController) {
        UIView *menuView    = menuViewController.view;
        menuView.accessibilityElementsHidden = YES;
        CGRect menuFrame = self.view.bounds;
        menuFrame.size.width = self.menuAbsoluteWidth + kAPLSlideMenuFirstOffset;
        menuFrame.origin.x = self.view.bounds.size.width - menuFrame.size.width;
        
        menuView.frame = menuFrame;
        menuView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
        
        [self addChildViewController:menuViewController];
        [self.view insertSubview:menuView atIndex:0];
        
        [menuViewController didMoveToParentViewController:self];
    }
}

- (void)setGestureSupport:(APLSlideMenuGestureSupportType)gestureSupport {
    _gestureSupport = gestureSupport;
    self.dragGestureRecognizer.enabled = gestureSupport != APLSlideMenuGestureSupportNone;
}

- (void)setMenuWidth:(CGFloat)menuWidth {
    if (_menuWidth == menuWidth) {
        return;
    }
    
    _menuWidth = menuWidth;
    
    if (self.leftMenuViewController) {
        CGRect menuFrame = self.leftMenuViewController.view.frame;
        menuFrame.size.width = self.menuAbsoluteWidth + kAPLSlideMenuFirstOffset;
        self.leftMenuViewController.view.frame = menuFrame;
    }
    
    if (self.rightMenuViewController) {
        CGRect menuFrame = self.rightMenuViewController.view.frame;
        menuFrame.size.width = self.menuAbsoluteWidth;
        menuFrame.origin.x = self.view.bounds.size.width - menuFrame.size.width;
        self.rightMenuViewController.view.frame = menuFrame;
    }
}

- (void)setUseShadow:(BOOL)useShadow {
    _useShadow = useShadow;
    self.contentContainerView.clipsToBounds = !useShadow || self.isDisplayMenuSideBySide;
}

- (void)setSeparatorColor:(UIColor *)separatorColor {
    _separatorColor = separatorColor;
    self.leftSeparatorView.backgroundColor = separatorColor;
    self.rightSeparatorView.backgroundColor = separatorColor;
}

#pragma mark - Menu view



- (void)setContentViewController:(UIViewController *)contentViewController animated:(BOOL)animated {
    
    if (_contentViewController) {
        [_contentViewController willMoveToParentViewController:nil];
        [_contentViewController.view removeFromSuperview];
        [_contentViewController removeFromParentViewController];
    }
    _contentViewController = contentViewController;
     
    if ([contentViewController isKindOfClass:[UINavigationController class]]) {
        ((UINavigationController*)contentViewController).delegate = self;
    }
    
    if (!contentViewController) {
        return;
    }

    [self addChildViewController:contentViewController];
    contentViewController.view.frame = self.contentContainerView.bounds;
    contentViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    CGRect currentFrame = self.view.bounds;
    if (self.activeMenuViewController == self.rightMenuViewController) {
        currentFrame.origin.x = -currentFrame.size.width;
    } else {
        currentFrame.origin.x = currentFrame.size.width;
    }
    self.contentContainerView.frame = currentFrame;
    [self.contentContainerView insertSubview:contentViewController.view atIndex:0];
    
    if (self.isMenuViewVisible) {
        currentFrame.origin.x = [self menuAbsoluteWidth];
    }
    else {
        currentFrame.origin.x = 0;
    }
    
    void (^animationBlock)()   = ^(){
        self.contentContainerView.frame = currentFrame;
    };
    void (^completionBlock)(BOOL) = ^(BOOL finished){
        [contentViewController didMoveToParentViewController:self];
    };
    
    if (animated) {
        [UIView animateWithDuration:kAPLSlideMenuDefaultAnimationDuration animations:animationBlock
                         completion:completionBlock];
    } else {
        animationBlock();
        completionBlock(YES);
    }

}

- (void) dismissContentViewController {
    [_contentViewController willMoveToParentViewController:nil];
    [_contentViewController.view removeFromSuperview];
    [_contentViewController removeFromParentViewController];
    _contentViewController = nil;
    
    // Reset visibility because the content view controller should be moved if setContentViewController is called.
    self.menuViewVisible = NO;
}


- (UIViewController*)getTopContentViewController {
    if ([self.contentViewController isKindOfClass:[UINavigationController class]]) {
        return ((UINavigationController*)self.contentViewController).topViewController;
    }
    return self.contentViewController;
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    // hack to trigger rotation to supported orientation in case this is not the topViewController
    if (([[navigationController viewControllers] count] < 2) || ([navigationController respondsToSelector:@selector(supportedInterfaceOrientations)] && ([navigationController supportedInterfaceOrientations] == UIInterfaceOrientationMaskAll))) return;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if (![self respondsToSelector:@selector(presentationController)]) {
#pragma clang diagnostic pop
        [self presentViewController:[UIViewController new] animated:NO completion:^{
            [self dismissViewControllerAnimated:NO completion:nil];
        }];
    }
}

#pragma mark - Screen setup

-(void)addShadowToView:(UIView*)aView {
    aView.clipsToBounds = !self.useShadow;
    aView.layer.shadowPath = [UIBezierPath bezierPathWithRect:aView.bounds].CGPath;
    aView.layer.shadowRadius = 10;
    aView.layer.shadowOpacity = 0.75;
    aView.layer.shadowOffset = CGSizeMake(0., 0.);
    aView.layer.shadowColor = [UIColor blackColor].CGColor;
}


#pragma mark - MenuHandling

- (BOOL)delegateVetosDragWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint inOrderToShowMenu:(BOOL)isGoingToShowMenuWhenThisGestureSucceeds {
    if ([self.slideDelegate respondsToSelector:@selector(shouldHandleSlideMenuGesture:startingAtPoint:withEndPoint:inOrderToShowMenu:)]) {
        return ![self.slideDelegate shouldHandleSlideMenuGesture:self startingAtPoint:startPoint withEndPoint:endPoint inOrderToShowMenu:isGoingToShowMenuWhenThisGestureSucceeds];
    }
    return NO;
}

- (void) dragGestureRecognizerDrag:(UIPanGestureRecognizer*)sender {
    if (self.keyboardVisible || self.isDisplayMenuSideBySide)
        return;
    
    CGPoint translation = [sender translationInView:self.view];
    CGFloat xTranslation = translation.x;
    CGFloat flickVelocitiy = 3.0;
    
    UIGestureRecognizerState state = sender.state;
    switch (state) {
        case UIGestureRecognizerStateBegan: {
            self.dragContentStartX = self.contentContainerView.frame.origin.x;
            self.dragGestureStartPoint = [sender locationInView:self.view];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if (self.gestureSupport == APLSlideMenuGestureSupportDrag ||
                self.gestureSupport == APLSlideMenuGestureSupportDragOnlyNavigationBar) {
                UIView *aView       = self.contentContainerView;
                CGRect contentFrame = aView.frame;
                
                // Correct position
                CGFloat newStartX  = self.dragContentStartX;
                newStartX += xTranslation;
                
                CGFloat endX = (self.menuWidth >= 0.0 && self.menuWidth <= 1.0) ? roundf(self.menuWidth*contentFrame.size.width) : self.menuWidth;
                
                newStartX = MIN(MAX(self.rightMenuViewController ? -endX : 0., newStartX), self.leftMenuViewController ? endX : 0.);
                if (newStartX < 0) {
                    [self.view sendSubviewToBack:self.leftMenuViewController.view];
                } else {
                    [self.view sendSubviewToBack:self.rightMenuViewController.view];
                }
                
                contentFrame.origin.x = newStartX;
                aView.frame = contentFrame;
            }
            break;
        }
        case UIGestureRecognizerStateEnded: {
            if (self.gestureSupport == APLSlideMenuGestureSupportBasic ||
                self.gestureSupport == APLSlideMenuGestureSupportBasicOnlyHorizontal) {
                
                BOOL hasCorrectAngle = YES;
                if (self.gestureSupport == APLSlideMenuGestureSupportBasicOnlyHorizontal) {
                    hasCorrectAngle = ABS(translation.x) > ABS(translation.y);
                }
                
                CGPoint endPoint = [sender locationInView:self.view];
                /*
                 * Spaghetti code ahead. Grab yourself some tomatoe sauce and enjoy.
                 * Yes, there are these many different cases.
                 */
                if (xTranslation > 0.0 && hasCorrectAngle) {
                    if (self.leftMenuViewController && !self.isMenuViewVisible) {
                        if (![self delegateVetosDragWithStartPoint:self.dragGestureStartPoint endPoint:endPoint inOrderToShowMenu:YES]) {
                            [self showLeftMenu:YES];
                        }
                    } else {
                        if (![self delegateVetosDragWithStartPoint:self.dragGestureStartPoint endPoint:endPoint inOrderToShowMenu:NO]) {
                            [self hideMenu:YES];
                        }
                    }
                } else if (xTranslation < 0.0 && hasCorrectAngle) {
                    if (self.rightMenuViewController && !self.isMenuViewVisible) {
                        if (![self delegateVetosDragWithStartPoint:self.dragGestureStartPoint endPoint:endPoint inOrderToShowMenu:YES]) {
                            [self showRightMenu:YES];
                        }
                    } else {
                        if (![self delegateVetosDragWithStartPoint:self.dragGestureStartPoint endPoint:endPoint inOrderToShowMenu:NO]) {
                            [self hideMenu:YES];
                        }
                    }
                }
            } else if (self.gestureSupport == APLSlideMenuGestureSupportDrag ||
                       self.gestureSupport == APLSlideMenuGestureSupportDragOnlyNavigationBar) {
                UIView *aView = self.contentContainerView;
                CGRect contentFrame = [aView frame];
                CGFloat currentX    = contentFrame.origin.x;
                
                if (((0. < currentX) && (flickVelocitiy < [sender velocityInView:self.contentContainerView].x)) ||
                    ((currentX < 0.) && ([sender velocityInView:self.contentContainerView].x < -flickVelocitiy))) {
                    if (xTranslation > 0.0) {
                        if (self.leftMenuViewController && !self.isMenuViewVisible) {
                            [self showLeftMenu:YES];
                        } else {
                            [self hideMenu:YES];
                        }
                    } else if (xTranslation < 0.0) {
                        if (self.rightMenuViewController && !self.isMenuViewVisible) {
                            [self showRightMenu:YES];
                        } else {
                            [self hideMenu:YES];
                        }
                    }
                } else {
                    CGFloat endX = (self.menuWidth >= 0.0 && self.menuWidth <= 1.0) ? roundf(self.menuWidth*contentFrame.size.width) : self.menuWidth;
                    
                    if (self.rightMenuViewController && !self.isMenuViewVisible && (currentX < -endX)) {
                        [self showRightMenu:YES];
                    } else if (self.leftMenuViewController && !self.isMenuViewVisible && (endX < currentX)) {
                        [self showLeftMenu:YES];
                    } else {
                        [self hideMenu:YES];
                    }
                }
            }
            // Reset drag content start x
            self.dragContentStartX = 0.0;
            self.dragGestureStartPoint = CGPointZero;
            break;
        }
        default:
            break;
    }
}

#pragma mark - Helper methods

-(void)notifyWillShowMenu {
    [[NSNotificationCenter defaultCenter] postNotificationName:APLSlideMenuWillShowNotification object:self];
}

-(void)notifyDidShowMenu {
    [[NSNotificationCenter defaultCenter] postNotificationName:APLSlideMenuDidShowNotification object:self];
}

-(void)notifyWillHideMenu {
     [[NSNotificationCenter defaultCenter] postNotificationName:APLSlideMenuWillHideNotification object:self];
}

-(void)notifyDidHideMenu {
     [[NSNotificationCenter defaultCenter] postNotificationName:APLSlideMenuDidHideNotification object:self];
}

- (void)showMenu:(BOOL)animated {
    [self showLeftMenu:animated];
}

- (void)showLeftMenu:(BOOL)animated {
    [self.view sendSubviewToBack:self.rightMenuViewController.view];
    [self showMenu:self.leftMenuViewController animated:animated];
}

- (void)showRightMenu:(BOOL)animated {
    [self.view sendSubviewToBack:self.leftMenuViewController.view];
    [self showMenu:self.rightMenuViewController animated:animated];
}

- (void)showMenu:(UIViewController*)viewController animated:(BOOL)animated {
    if (self.isDisplayMenuSideBySide) return;
    
    CGFloat direction = (viewController == self.leftMenuViewController) ? 1. : -1.;
    
    viewController.view.accessibilityElementsHidden = NO;
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, viewController.view);
    
    void(^showMenuCompletionBlock)(BOOL) = ^(BOOL finished) {
        self.activeMenuViewController = viewController;
        self.menuViewVisible = YES;
        if (self.tapOnContentViewToHideMenu) {
            [self.contentContainerView addGestureRecognizer:self.hideTapGestureRecognizer];
            self.contentViewController.view.userInteractionEnabled = NO;
        }
        if (self.slideDelegate && [self.slideDelegate respondsToSelector:@selector(didShowMenu:)]) {
            [self.slideDelegate didShowMenu:self];
        }
        [self notifyDidShowMenu];
    };
    
    void(^showBouncingBlock)() = ^{
        __block CGRect contentFrame = [self.contentContainerView frame];
        __block CGFloat endx = direction * ((self.menuWidth >= 0.0 && self.menuWidth <= 1.0) ? roundf(self.menuWidth*contentFrame.size.width) : self.menuWidth);
        
        contentFrame.origin.x = endx + direction * kAPLSlideMenuFirstOffset;
        
        [UIView animateWithDuration:kAPLSlideMenuDefaultBounceDuration
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.contentContainerView.frame = contentFrame;
                         }
                         completion:^(BOOL finished) {
                             contentFrame.origin.x = endx;
                             [UIView  animateWithDuration:kAPLSlideMenuDefaultBounceDuration
                                                    delay:0.0
                                                  options:UIViewAnimationOptionCurveEaseInOut
                                               animations:^{
                                                   self.contentContainerView.frame = contentFrame;
                                               }
                                               completion:showMenuCompletionBlock];
                         }];
    };
    
    void(^showMenuBlock)() = ^{
        CGRect contentFrame = [self.contentContainerView frame];
        contentFrame.origin.x = direction * ((self.menuWidth >= 0.0 && self.menuWidth <= 1.0) ? roundf(self.menuWidth*contentFrame.size.width) : self.menuWidth);
        self.contentContainerView.frame = contentFrame;
    };
    
    if (self.slideDelegate && [self.slideDelegate respondsToSelector:@selector(willShowMenu:)]) {
        [self.slideDelegate willShowMenu:self];
    }
    [self notifyWillShowMenu];
    
    if (animated) {
        if (self.isBouncing) {
            showBouncingBlock();
        } else {
            [UIView animateWithDuration:self.animationDuration animations:showMenuBlock completion:showMenuCompletionBlock];
        }
    } else {
        showMenuBlock();
        showMenuCompletionBlock(YES);
    }
}

- (void)hideMenu:(BOOL)animated {
    if (self.isDisplayMenuSideBySide) return;
    
    CGFloat direction = (self.activeMenuViewController == self.leftMenuViewController) ? 1. : -1.;
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.contentViewController.view);
    self.leftMenuViewController.view.accessibilityElementsHidden = YES;
    self.rightMenuViewController.view.accessibilityElementsHidden = YES;
    
    void (^hideMenuCompletionBlock)(BOOL) = ^(BOOL finished) {
        self.menuViewVisible = NO;
        if (self.tapOnContentViewToHideMenu) {
            [self.contentContainerView removeGestureRecognizer:self.hideTapGestureRecognizer];
            self.contentViewController.view.userInteractionEnabled = YES;
        }
        
        if (self.slideDelegate && [self.slideDelegate respondsToSelector:@selector(didHideMenu:)]) {
            [self.slideDelegate didHideMenu:self];
        }
        [self notifyDidHideMenu];
    };
    
    void(^hideBouncingBlock)() = ^{
        __block CGRect contentFrame = [self.contentContainerView frame];
        
        contentFrame.origin.x = -1. * direction * kAPLSlideMenuFirstOffset;
        [UIView animateWithDuration:kAPLSlideMenuDefaultBounceDuration
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.contentContainerView.frame = contentFrame;
                         }
                         completion:^(BOOL finished) {
                             contentFrame.origin.x = 0.0;
                             [UIView  animateWithDuration:kAPLSlideMenuDefaultBounceDuration
                                                    delay:0.0
                                                  options:UIViewAnimationOptionCurveEaseInOut
                                               animations:^{
                                                   self.contentContainerView.frame = contentFrame;
                                               }
                                               completion:hideMenuCompletionBlock];
                         }];
    };
    
    void(^hideMenuBlock)() = ^{
        CGRect contentFrame = [self.contentContainerView frame];
        contentFrame.origin.x = 0.0;
        self.contentContainerView.frame = contentFrame;
    };
    
    if (self.slideDelegate && [self.slideDelegate respondsToSelector:@selector(willHideMenu:)]) {
        [self.slideDelegate willHideMenu:self];
    }
    [self notifyWillHideMenu];
    
    if (animated) {
        if (self.isBouncing) {
            hideBouncingBlock();
        } else {
            [UIView animateWithDuration:self.animationDuration animations:hideMenuBlock completion:hideMenuCompletionBlock];
        }
    } else {
        hideMenuBlock();
        hideMenuCompletionBlock(YES);
    }
}

- (void)switchMenu:(BOOL)animated {
    [self switchLeftMenu:animated];
}

-(void) switchLeftMenu:(BOOL) animated {
    if (self.isMenuViewVisible) {
        [self hideMenu:animated];
    } else {
        [self showLeftMenu:animated];
    }
}

-(void) switchRightMenu:(BOOL) animated {
    if (self.isMenuViewVisible) {
        [self hideMenu:animated];
    } else {
        [self showRightMenu:animated];
    }
}

- (void) keyboardWillShow:(NSNotification*)notification {
    self.keyboardVisible = YES;
}

- (void) keyboardDidHide:(NSNotification*)notification {
    self.keyboardVisible = NO;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (self.isMenuViewVisible) {
        return YES;
    }
    if (self.gestureSupport == APLSlideMenuGestureSupportNone) {
        return NO;
    }
    if (self.gestureSupport == APLSlideMenuGestureSupportDragOnlyNavigationBar) {
        UIView *navigationBar = [self.contentContainerView APLSlideMenuViewController_findSubviewOfClass:[UINavigationBar class]];
        if (!CGRectContainsPoint(navigationBar.bounds, [gestureRecognizer locationInView:navigationBar]))
            return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    // prevent recognizing touches on the slider
    UIView *view = touch.view;
    while (view) {
        if ([view isKindOfClass:[UISlider class]] || [view isKindOfClass:[UISwitch class]])
            return NO;
        view = view.superview;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return (gestureRecognizer != self.dragGestureRecognizer) || ![otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]];
}

- (IBAction)closeTapGestureRecognizerFired:(UIGestureRecognizer*)sender {
    [self hideMenu:YES];
}

@end

//----------------------------------------------

@implementation UIViewController (APLSlideMenuViewController)

- (APLSlideMenuViewController*) slideMenuController {
    UIViewController *currentViewController = self;
    while ((currentViewController = currentViewController.parentViewController)) {
        if ([currentViewController isKindOfClass:[APLSlideMenuViewController class]]) {
            return (APLSlideMenuViewController*) currentViewController;
        }
    }
    return nil;
}

@end
