//
//  AppDelegate.m
//  FSQCellManifestExample
//
//  Created by Brian Dorfman on 2/3/15.
//  Copyright (c) 2015 Foursquare. All rights reserved.
//

#import "AppDelegate.h"

#import "FSQExampleManifestTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    FSQExampleManifestTableViewController *exampleController = [[FSQExampleManifestTableViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:exampleController];
    
    self.window.rootViewController = navController;
    return YES;
}


@end

NS_ASSUME_NONNULL_END
