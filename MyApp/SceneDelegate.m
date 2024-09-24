//
//  SceneDelegate.m
//  MyApp
//
//  Created by Jinwoo Kim on 9/24/24.
//

#import "SceneDelegate.h"
#import "AudioViewController.h"

@interface SceneDelegate ()

@end

@implementation SceneDelegate

- (void)dealloc {
    [_window release];
    [super dealloc];
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    
    AudioViewController *audioViewController = [AudioViewController new];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:audioViewController];
    [audioViewController release];
    
    window.rootViewController = navigationController;
    [navigationController release];
    
    self.window = window;
    [window makeKeyAndVisible];
    [window release];
}

@end
