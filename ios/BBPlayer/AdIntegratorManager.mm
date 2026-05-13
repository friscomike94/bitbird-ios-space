//
//  AdIntegratorManager.m
//  BBPlayer
//
//  Created by Cody Thompson on 11/14/19.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ads/PTAdInvoker.h"
#import "AppDelegate.h"
#import "AdIntegratorManager.h"
#import "AdNetworkConsentManager.h"

#import <AOBSessionReporting/AOBSessionReporting.h>

#define CLASSNAME_KEY @"integratorClassPath"
#define CUSTOM_NETWORK_ID @"custom"
#define CUSTOM_CLASSNAME @"CustomAdIntegrator"

@implementation AdIntegratorManager

// TODO: map of multiple ad integrators

+ (id)shared {
    static AdIntegratorManager* manager = nil;
    @synchronized(self){
        if(manager == nil){
            manager = [[self alloc] init];
        }
    }
    return manager;
}

- (id)init {
    self = [super init];
    _integrators = [NSMutableDictionary dictionary];
    return self;
}

/**
    Provides a boolean value to the integrator that indicates whether or not consent for perzonalized ads has been given.
    DOES NOTE UPDATE THE CONSENT MANAGER. The value of the consented param should be retrieved FROM the consent manager.
 */
- (void)setIntegratorConsent:(NSObject *)integrator withConsentValue:(bool)consented {
    @try {
        [BridgeHelper setConsent:integrator withConsentValue:consented];
    }
    @catch (NSException* e) {
        NSString* errMsg = [NSString stringWithFormat:@"Unable to successfully call 'setConsent:'"];
        @throw [NSException
                exceptionWithName:@"BuildboxAdIntegratorException"
                reason:errMsg
                userInfo:nil];
    }
}

- (void)initAdNetwork:(NSString*) networkId withKeyValuePairs:(NSDictionary<NSString*,NSString*>*)keyValuePairs {
    NSString* integratorClassName = [keyValuePairs objectForKey:CLASSNAME_KEY];
    NSObject* integrator = [BridgeHelper getIntegrator:integratorClassName];
    if (integrator == nil) {
        NSString* errMsg = [NSString stringWithFormat:@"Invalid network integrator class name or class missing '+ shared(id)' method. Classname: %@", integratorClassName];
        @throw [NSException
                exceptionWithName:@"BuildboxAdIntegratorException"
                reason:errMsg
                userInfo:nil];
    }
    else {
        NSString* errMsg = [BridgeHelper validateIntegrator:integrator];
        if (errMsg != nil) {
            @throw [NSException
                    exceptionWithName:@"BuildboxAdIntegratorException"
                    reason:errMsg
                    userInfo:nil];
        }
        else {
            [_integrators setValue:integrator forKey:networkId];
            AppDelegate* app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            UIViewController* vc = app.window.rootViewController;
            
            @try {
                if ([networkId isEqualToString:CUSTOM_NETWORK_ID]) {
                    [BridgeHelper initAdNetwork:integrator withNetworkId:networkId withViewController:vc];
                }
                else {
                    bool consented = [[AdNetworkConsentManager sharedManager] getConsentStatusForNetworkWithName:networkId];
                    [self setIntegratorConsent:integrator withConsentValue:consented];
                    [BridgeHelper initAdNetwork:integrator withNetworkId:networkId withKeyValuePairs:keyValuePairs withViewController:vc];
                }
            }
            @catch (NSException* e) {
                NSString* errMsg;
                if ([e.name isEqualToString:@"BuildboxAdIntegratorException"]) {
                    errMsg = [NSString stringWithFormat:@"%@ for integrator with class name: '%@'", e.reason, integratorClassName];
                }
                else {
                    errMsg = [NSString stringWithFormat:@"Unable to successfully call 'initAdNetwork:withNetworkId:withKeyValuePairs:withViewController:' for integrator with class name: '%@'", integratorClassName];
                }
                @throw [NSException
                        exceptionWithName:@"BuildboxAdIntegratorException"
                        reason:errMsg
                        userInfo:nil];
            }
        }
    }
}

- (NSObject*)getIntegrator:(NSString*)networkId {
    return [_integrators objectForKey:networkId];
}

- (void)revokeAllConsent {
    for (id networkId in _integrators) {
        NSObject* integrator = [self getIntegrator:networkId];
        [self setIntegratorConsent:integrator withConsentValue:false];
    }
    [[AdNetworkConsentManager sharedManager] consentToAllNetworksDeclined];
    
    // show an alert
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Consent Revoked" message:@"Consent revoked for all ad networks" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil]];
    AppDelegate* app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    UIViewController* vc = app.window.rootViewController;
    [vc presentViewController:alert animated:NO completion:nil];
}

/*
 * returns true of false based on whether or not an integrator matching the networkId was found
 */
- (bool)tryVoidIntegratorMethod:(NSString*)methodName forNetwork:(NSString*)networkId {
    NSObject* integrator = [self getIntegrator:networkId];
    if (integrator == nil) {
        NSLog(@"[AdIntegratorManager][%@] Unknown network id! %@", methodName, networkId);
        return false;
    }
    @try {
        [BridgeHelper callVoidMethod:methodName withObj:integrator];
    }
    @catch (NSException* e) {
        NSString* errMsg = [NSString stringWithFormat:@"Unable to successfully call '%@' for integrator with network ID %@", methodName, networkId];
        @throw [NSException
                exceptionWithName:@"BuildboxAdIntegratorException"
                reason:errMsg
                userInfo:nil];
    }
    return true;
}

/*
* Unlike tryVoidIntegratorMethod, expects an integrator obj instead of a network ID
* returns the result of the integrator method
*/
- (bool) tryAndReturnBoolIntegratorMethod:(NSString*)methodName forIntegrator:(NSObject*)integrator {
    bool result;
    @try {
        result = [BridgeHelper callBoolMethod:methodName withObj:integrator];
    }
    @catch (NSException* e) {
        NSString* errMsg = [NSString stringWithFormat:@"Unable to successfully call '%@'", methodName];
        @throw [NSException
                exceptionWithName:@"BuildboxAdIntegratorException"
                reason:errMsg
                userInfo:nil];
    }
    return result;
}

- (void)initBanner:(NSString*)networkId {
    if (![self tryVoidIntegratorMethod:@"initBanner" forNetwork:networkId]) {
        [self bannerFailed:networkId];
    }
}
- (void)initInterstitial:(NSString*)networkId {
    if (![self tryVoidIntegratorMethod:@"initInterstitial" forNetwork:networkId]) {
        [self interstitialFailed:networkId];
    }
}
- (void)initRewardedVideo:(NSString*)networkId{
    if (![self tryVoidIntegratorMethod:@"initRewardedVideo" forNetwork:networkId]) {
        [self rewardedVideoFailed:networkId];
    }
}

- (void)showBanner:(NSString*)networkId {
    if (![self tryVoidIntegratorMethod:@"showBanner" forNetwork:networkId]) {
        [self bannerFailed:networkId];
    }
}
- (void)hideBanner:(NSString*)networkId{
    if (![self tryVoidIntegratorMethod:@"hideBanner" forNetwork:networkId]) {
        [self bannerFailed:networkId];
    }
}
- (void)showInterstitial:(NSString*)networkId{
    if (![self tryVoidIntegratorMethod:@"showInterstitial" forNetwork:networkId]) {
        [self interstitialFailed:networkId];
    }
}
- (void)showRewardedVideo:(NSString*)networkId{
    if (![self tryVoidIntegratorMethod:@"showRewardedVideo" forNetwork:networkId]) {
        [self rewardedVideoFailed:networkId];
    }
}

- (bool)isBannerVisible:(NSString*)networkId{
    NSObject* integrator = [self getIntegrator:networkId];
    if (integrator == nil) {
        NSLog(@"[AdIntegratorManager][isBannerVisible] Unknown network id! %@", networkId);
        [self bannerFailed:networkId];
        return false;
    }
    else {
        return [self tryAndReturnBoolIntegratorMethod:@"isBannerVisible" forIntegrator:integrator];
    }
}
- (bool)isRewardedVideoAvailable:(NSString*)networkId{
    NSObject* integrator = [self getIntegrator:networkId];
    if (integrator == nil) {
        NSLog(@"[AdIntegratorManager][isRewardedVideoAvailable] Unknown network id! %@", networkId);
        [self rewardedVideoFailed:networkId];
        return false;
    }
    else {
        return [self tryAndReturnBoolIntegratorMethod:@"isRewardedVideoAvailable" forIntegrator:integrator];
    }
}

- (void)networkLoaded:(NSString*) adNetworkId {
    PTAdInvoker::shared()->networkLoaded([adNetworkId cStringUsingEncoding:NSASCIIStringEncoding]);
}

- (void)networkFailed:(NSString*) adNetworkId {
    PTAdInvoker::shared()->networkFailed([adNetworkId cStringUsingEncoding:NSASCIIStringEncoding]);
}

- (void)bannerImpression:(NSString*) adNetworkId {
    AOBSendBannerAdAttemptReport(adNetworkId, true);
}

- (void)interstitialImpression:(NSString*) adNetworkId {
    AOBSendInterstitialAdAttemptReport(adNetworkId, true);
}

- (void)rewardedVideoImpression:(NSString*) adNetworkId {
    AOBSendRewardedAdAttemptReport(adNetworkId, true);
}

- (void)bannerLoaded:(NSString*) adNetworkId {
	PTAdInvoker::shared()->bannerLoaded([adNetworkId cStringUsingEncoding:NSASCIIStringEncoding]);
}

- (void)bannerFailed:(NSString*) adNetworkId {
	PTAdInvoker::shared()->bannerFailed([adNetworkId cStringUsingEncoding:NSASCIIStringEncoding]);
    AOBSendBannerAdAttemptReport(adNetworkId, false);
}

- (void)interstitialLoaded:(NSString*) adNetworkId {
    PTAdInvoker::shared()->interstitialLoaded([adNetworkId cStringUsingEncoding:NSASCIIStringEncoding]);
}

- (void)interstitialFailed:(NSString*) adNetworkId {
    PTAdInvoker::shared()->interstitialFailed([adNetworkId cStringUsingEncoding:NSASCIIStringEncoding]);
    AOBSendInterstitialAdAttemptReport(adNetworkId, false);
}

- (void)interstitialClosed:(NSString*) adNetworkId {
    PTAdInvoker::shared()->interstitialClosed([adNetworkId cStringUsingEncoding:NSASCIIStringEncoding]);
}

- (void)rewardedVideoLoaded:(NSString*) adNetworkId {
	PTAdInvoker::shared()->rewardedVideoLoaded([adNetworkId cStringUsingEncoding:NSASCIIStringEncoding]);
}

- (void)rewardedVideoFailed:(NSString*) adNetworkId {
	PTAdInvoker::shared()->rewardedVideoFailed([adNetworkId cStringUsingEncoding:NSASCIIStringEncoding]);
    AOBSendRewardedAdAttemptReport(adNetworkId, false);
}

- (void)rewardedVideoDidReward:(NSString*) adNetworkId {
	PTAdInvoker::shared()->rewardedVideoDidReward([adNetworkId cStringUsingEncoding:NSASCIIStringEncoding], true);
}

- (void)rewardedVideoDidEnd:(NSString*) adNetworkId {
	PTAdInvoker::shared()->rewardedVideoDidEnd([adNetworkId cStringUsingEncoding: NSASCIIStringEncoding], true);
}

@end
