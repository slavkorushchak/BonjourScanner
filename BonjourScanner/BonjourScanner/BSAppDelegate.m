//
//  BSAppDelegate.m
//  BonjourScanner
//
//  Created by Slavko Rushchak on 8/10/13.
//  Copyright (c) 2013 Slavko Rushchak. All rights reserved.
//

#import "BSAppDelegate.h"

#import "BSViewController.h"

@implementation BSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        _viewController = [[BSViewController alloc] initWithNibName:@"BSViewController_iPhone" bundle:nil];
    } else {
        _viewController = [[BSViewController alloc] initWithNibName:@"BSViewController_iPad" bundle:nil];
    }
    
    UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:_viewController];
    self.window.rootViewController = navController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{

}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
 
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (self.viewController) {
        [self.viewController refreshServicesList];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{

}

@end
