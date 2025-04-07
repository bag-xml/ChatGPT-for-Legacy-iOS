//
//  CGAppDelegate.m
//  ChatGPT
//
//  Created by XML on 1/13/25.
//  Copyright (c) 2025 XML. All rights reserved.
//

#import "CGAppDelegate.h"

@implementation CGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    bool nFL = [[NSUserDefaults standardUserDefaults] boolForKey:@"nFL"];
    
    if(nFL == NO) {
        [[NSUserDefaults standardUserDefaults] setObject:@"gpt-4o-mini" forKey:@"c-aiModel"];
        [[NSUserDefaults standardUserDefaults] setObject:@"dall-e-3" forKey:@"i-aiModel"];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"nFL"];
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"aFL"];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"Will resign active");
    [[NSUserDefaults standardUserDefaults] synchronize];
    bool yougetwhatimean = [[NSUserDefaults standardUserDefaults] boolForKey:@"firstLaunch"];
    if(yougetwhatimean == YES)
        [self checkAPICredentials];
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"Did enter background");
    [NSNotificationCenter.defaultCenter postNotificationName:@"SAVE CHAT" object:nil];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"Will enter foreground");
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"Did become active");
    [NSNotificationCenter.defaultCenter postNotificationName:@"RE-CHECK CONVOS" object:nil];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"Will terminate");
    //Save it HERE
    [NSNotificationCenter.defaultCenter postNotificationName:@"SAVE CHAT" object:nil];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)checkAPICredentials {
    if(apiKey == nil) {
        [CGAPIHelper alert:@"Warning" withMessage:@"Your API Key is missing, please double-check the settings pane and make sure you've inputted an OpenAI API Key."];
    } else if([apiKey isEqual:@""]) {
        [CGAPIHelper alert:@"Warning" withMessage:@"Your API Key is missing, please double-check the settings pane and make sure you've inputted an OpenAI API Key."];
    } else {
        [CGAPIHelper checkForAPIKeyValidity];
    }
}

@end
