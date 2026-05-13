//
//  AppDelegate.m
//  BBPlayer
//
//  Created by Nik Rudenko on 9/12/17.
//
//

#import "AppDelegate.h"
#import <GLKit/GLKit.h>
#include "PTPSettingsController.h"
#include "libs/cocos2dx/include/audio/include/SimpleAudioEngine.h"
#include "AdNetworkConsentManager.h"

#import <AOBSessionReporting/AOBSessionReporting.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
	[[AdNetworkConsentManager sharedManager] setupAdNetworks];
    AOBStartSessionReporting(@"3.1.2");
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    cocos2d::Director::getInstance()->stopAnimation();
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    cocos2d::Application::getInstance()->applicationDidEnterBackground();
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    cocos2d::Application::getInstance()->applicationWillEnterForeground();
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    cocos2d::Director::getInstance()->startAnimation();
}

- (void)applicationWillTerminate:(UIApplication *)application {
    AOBStopSessionReporting();
}

- (void)loadingDidComplete{
}

-(void)showCustomFullscreenAd{
}

- (void)screenOnEnter:(const char*) name{
}

- (void)screenOnExit:(const char*) name{
}

@end
