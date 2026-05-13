//
//  AdIntegratorManager.h
//  BBPlayer
//
//  Created by Cody Thompson on 11/14/19.
//

#ifndef AdIntegratorManager_h
#define AdIntegratorManager_h

//#import "ads/PTAdInvoker.h
#import "ads/PTAdInvoker.h"
#import "BridgeHelper.h"

@interface AdIntegratorManager : NSObject {
    NSDictionary<NSString*,NSObject*>* _integrators;
}

+ (id)shared;

- (void)setIntegratorConsent:(NSObject *)integrator withConsentValue:(bool)consented;
- (void)initAdNetwork:(NSString*)networkClassName withKeyValuePairs:(NSDictionary<NSString*,NSString*>*)keyValuePairs;
- (void)networkLoaded:(NSString*)networkId;
- (void)networkFailed:(NSString*)networkId;
- (NSObject*)getIntegrator:(NSString*)networkId;
- (bool)tryVoidIntegratorMethod:(NSString*)methodName forNetwork:(NSString*)networkId;

- (void)initBanner:(NSString*)networkClassName;
- (void)initInterstitial:(NSString*)networkClassName;
- (void)initRewardedVideo:(NSString*)networkClassName;

- (void)showBanner:(NSString*)networkClassName;
- (void)hideBanner:(NSString*)networkClassName;
- (void)showInterstitial:(NSString*)networkClassName;
- (void)showRewardedVideo:(NSString*)networkClassName;

- (bool)isBannerVisible:(NSString*)networkClassName;
- (bool)isRewardedVideoAvailable:(NSString*)networkClassName;

- (void)revokeAllConsent;

// TODO, add the missing methods

- (void)bannerImpression:(NSString*) adNetworkId;
- (void)interstitialImpression:(NSString*) adNetworkId;
- (void)rewardedVideoImpression:(NSString *)adNetworkId;

- (void)bannerLoaded:(NSString*) adNetworkId;
- (void)bannerFailed:(NSString*) adNetworkId;

- (void)interstitialLoaded:(NSString*) adNetworkId;
- (void)interstitialFailed:(NSString*) adNetworkId;
- (void)interstitialClosed:(NSString*) adNetworkId;

- (void)rewardedVideoLoaded:(NSString*) adNetworkId;
- (void)rewardedVideoFailed:(NSString*) adNetworkId;
- (void)rewardedVideoDidReward:(NSString*) adNetworkId;
- (void)rewardedVideoDidEnd:(NSString*) adNetworkId;

@end

#endif /* AdIntegratorManager_h */
