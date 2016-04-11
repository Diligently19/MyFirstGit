//
//  AppDelegate.m
//  TestGoogleMaps
//
//  Created by appledev064 on 4/6/16.
//  Copyright © 2016 appledev064. All rights reserved.
//

#import "AppDelegate.h"
@import GoogleMaps;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [GMSServices provideAPIKey:@"AIzaSyAs697ORtYmqIGSbC6VK6BislNiEBK-bhE"];
    return YES;
}
@end
