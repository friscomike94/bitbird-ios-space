//
//  AdIntegratorInterface.h
//  BuildboxAdIntegratorInterface
//
//  Created by Cody Thompson on 11/26/19.
//  Copyright © 2019 AppOnboard. All rights reserved.
//

#ifndef AdIntegratorInterface_h
#define AdIntegratorInterface_h

@interface AdIntegratorInterface : NSObject

+ (void)networkLoaded:(NSString*)networkId;
+ (void)networkFailed:(NSString*)networkId;
+ (void)interstitialLoaded:(NSString*)networkId;
+ (void)interstitialImpression:(NSString *)networkId;
+ (void)interstitialFailed:(NSString*)networkId;
+ (void)interstitialClosed:(NSString*)networkId;
+ (void)bannerLoaded:(NSString*)networkId;
+ (void)bannerImpression:(NSString *)networkId;
+ (void)bannerFailed:(NSString*)networkId;
+ (void)rewardedVideoLoaded:(NSString*) adNetworkId;
+ (void)rewardedVideoImpression:(NSString *)networkId;
+ (void)rewardedVideoFailed:(NSString *)adNetworkId;
+ (void)rewardedVideoDidReward:(NSString*) adNetworkId;
+ (void)rewardedVideoDidEnd:(NSString*) adNetworkId;


@end

#endif /* AdIntegratorInterface_h */
