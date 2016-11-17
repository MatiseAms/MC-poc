//
//  AppDelegate.m
//  expeditiewadden
//
//  Created by Timan Rebel on 17/11/2016.
//  Copyright © 2016 Timan Rebel. All rights reserved.
//

#import "AppDelegate.h"
#import "ETPush.h"

// AppCenter AppIDs and Access Tokens for the debug and production versions of your app
// These values should be stored securely by your application or retrieved from a remote server
static NSString *kETAppID_Debug       = @"fcfd49e6-3acb-4b81-94c5-fa068f38caee";            // uses Sandbox APNS for debug builds
static NSString *kETAccessToken_Debug = @"ekhwsxafuxgwqyk5smt6twnu";
static NSString *kETAppID_Prod        = @"cf312f62-6a30-44b4-9fe6-6617f7ee997a";       // uses Production APNS
static NSString *kETAccessToken_Prod  = @"28wn56zxuweuta2qzrqbfy3v";

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL successful = NO;
    NSError *error = nil;
#ifdef DEBUG
    // Set to YES to enable logging while debugging
    [ETPush setETLoggerToRequiredState:YES];
    
    // configure and set initial settings of the JB4ASDK
    successful = [[ETPush pushManager] configureSDKWithAppID:kETAppID_Debug
                                              andAccessToken:kETAccessToken_Debug
                                               withAnalytics:YES
                                         andLocationServices:YES       // ONLY SET TO YES IF PURCHASED AND USING GEOFENCE CAPABILITIES
                                        andProximityServices:YES       // ONLY SET TO YES IF PURCHASED AND USING BEACONS
                                               andCloudPages:NO       // ONLY SET TO YES IF PURCHASED AND USING CLOUDPAGES
                                             withPIAnalytics:YES
                                                       error:&error];
#else
    // configure and set initial settings of the JB4ASDK
    successful = [[ETPush pushManager] configureSDKWithAppID:kETAppID_Prod
                                              andAccessToken:kETAccessToken_Prod
                                               withAnalytics:YES
                                         andLocationServices:YES       // ONLY SET TO YES IF PURCHASED AND USING GEOFENCE CAPABILITIES
                                        andProximityServices:YES       // ONLY SET TO YES IF PURCHASED AND USING BEACONS
                                               andCloudPages:NO       // ONLY SET TO YES IF PURCHASED AND USING CLOUDPAGES
                                             withPIAnalytics:YES
                                                       error:&error];
    
#endif
    //
    // if configureSDKWithAppID returns NO, check the error object for detailed failure info. See PushConstants.h for codes.
    // the features of the JB4ASDK will NOT be useable unless configureSDKWithAppID returns YES.
    //
    if (!successful) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // something failed in the configureSDKWithAppID call - show what the error is
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed configureSDKWithAppID!", @"Failed configureSDKWithAppID!")
                                        message:[error localizedDescription]
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                              otherButtonTitles:nil] show];
        });
    }
    else {
        // register for push notifications - enable all notification types, no categories
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:
                                                UIUserNotificationTypeBadge |
                                                UIUserNotificationTypeSound |
                                                UIUserNotificationTypeAlert
                                                                                 categories:nil];
        
        [[ETPush pushManager] registerUserNotificationSettings:settings];
        [[ETPush pushManager] registerForRemoteNotifications];
        
        // inform the JB4ASDK of the launch options
        // possibly UIApplicationLaunchOptionsRemoteNotificationKey or UIApplicationLaunchOptionsLocalNotificationKey
        [[ETPush pushManager] applicationLaunchedWithOptions:launchOptions];
        
        // This method is required in order for location messaging to work and the user's location to be processed
        // Only call this method if you have LocationServices set to YES in configureSDK()
        [[ETLocationManager sharedInstance] startWatchingLocation];
        
        if([[[UIDevice currentDevice] systemVersion] floatValue] >=7.0)
        {
            if ( [[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusAvailable )
            {
                // setting this will enable iOS to call the app delegate method performFetchWithCompletionHandler periodically. The implementation of that method (see below)
                // will call the JB4ASDK at most once per day to update location and proximity messages in the background - if those services have been enabled.
                // Only call this method if you have LocationServices set to YES in configureSDK()
                // Note that you will require "App downloads content from the network" in your plist for this background app refresh to work
                [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
            }
        }
    }
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    // inform the JB4ASDK of the notification settings requested
    [[ETPush pushManager] didRegisterUserNotificationSettings:notificationSettings];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    // inform the JB4ASDK of the device token
    [[ETPush pushManager] registerDeviceToken:deviceToken];
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    // inform the JB4ASDK that the device failed to register and did not receive a device token
    [[ETPush pushManager] applicationDidFailToRegisterForRemoteNotificationsWithError:error];
}


-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    // inform the JB4ASDK that the device received a local notification
    [[ETPush pushManager] handleLocalNotification:notification];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler {
    
    // inform the JB4ASDK that the device received a remote notification
    [[ETPush pushManager] handleNotification:userInfo forApplicationState:application.applicationState];
    
    // is it a silent push?
    if (userInfo[@"aps"][@"content-available"]) {
        // received a silent remote notification...
        
        // indicate a silent push
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];
    }
    else {
        // received a remote notification...
        
        // clear the badge
        [[ETPush pushManager] resetBadgeCount];
    }
    
    handler(UIBackgroundFetchResultNoData);
}

-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult)) completionHandler
{
    [[ETPush pushManager] refreshWithFetchCompletionHandler:completionHandler];
}


@end
