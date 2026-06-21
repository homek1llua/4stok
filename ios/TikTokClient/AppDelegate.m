#import "AppDelegate.h"
#import "APIClient.h"
#import "User.h"
#import "LoginViewController.h"
#import "FeedViewController.h"
#import "UploadViewController.h"
#import "ProfileViewController.h"
#import "SearchViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.backgroundColor = [UIColor blackColor];

  [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
  [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
  [[UITabBar appearance] setBarStyle:UIBarStyleBlack];
  [[UITabBar appearance] setTintColor:[UIColor whiteColor]];

  if ([APIClient sharedClient].token) {
    [self showMain];
  } else {
    [self showAuth];
  }

  [self.window makeKeyAndVisible];
  return YES;
}

- (void)showAuth {
  LoginViewController *loginVC = [[LoginViewController alloc] init];
  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
  self.window.rootViewController = nav;
}

- (void)showMain {
  FeedViewController *feedVC = [[FeedViewController alloc] init];
  feedVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"For You" image:[UIImage imageNamed:@"play"] tag:0];

  SearchViewController *searchVC = [[SearchViewController alloc] init];
  searchVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Search" image:[UIImage imageNamed:@"search"] tag:1];

  UploadViewController *uploadVC = [[UploadViewController alloc] init];
  uploadVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Upload" image:[UIImage imageNamed:@"upload"] tag:2];

  ProfileViewController *profileVC = [[ProfileViewController alloc] init];
  profileVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Profile" image:[UIImage imageNamed:@"person"] tag:3];
  profileVC.userId = [User currentUser].userId;

  UITabBarController *tabBar = [[UITabBarController alloc] init];
  tabBar.viewControllers = @[
    [[UINavigationController alloc] initWithRootViewController:feedVC],
    [[UINavigationController alloc] initWithRootViewController:searchVC],
    [[UINavigationController alloc] initWithRootViewController:uploadVC],
    [[UINavigationController alloc] initWithRootViewController:profileVC]
  ];
  tabBar.tabBar.barTintColor = [UIColor blackColor];
  tabBar.tabBar.translucent = NO;

  self.mainTabBarController = tabBar;
  self.window.rootViewController = tabBar;
}

@end
