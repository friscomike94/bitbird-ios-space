/*
 Edit this file to integrate a 3rd party ad network.
 
 Fill out the stubbed methods in the section labeled
 "Complete the following stubbed..."
 Call methods in the section labeled
 "Call these methods..."
 to inform the buildbox player of various events (i.e. a rewarded video was played
 and the user deserves a reward)
 
 NOTE: this class is ignored in the free version of Buildbox.
 */

#import <UIKit/UIKit.h>
#import <BuildboxAdIntegratorInterface/BuildboxAdIntegratorInterface.h>
#import "CustomAdIntegrator.h"

// TODO - Set to implemented network name here
#define CustomNetworkName @""

@implementation CustomAdIntegrator

+ (id)shared{
    static CustomAdIntegrator* integrator = nil;
    @synchronized(self){
        if(integrator == nil){
            integrator = [[self alloc] init];
        }
    }
    return integrator;
}

#pragma mark Complete the following stubbed methods. They will be called automatically by the Buildbox player.

/**
  This method will be called when the user has decided to change their acceptance of a privacy policy. This will usually mean that the user has pressed a "Revoke Consent Buton"
 */
- (void)setConsent:(bool)consented {
    // tell your network that the user doesn't consent to collecting of information
    NSLog(@"[CustomAdIntegrator setConsent] %@", consented? @"YES": @"NO");
}

/**
 * Use this method to initialize the Ad network only. Do not start loading ads here. If you are supporting banners,
 * then make sure to set the bannerView to not visible (i.e. [_bannerView setHidden:YES])
 * @param networkId - needs to be provided to the buildbox callbacks
 * @param viewController -Use this view controller if the ad network you are integrating with requires one
 */
- (void)initAdNetwork:(NSString*)networkId
   withViewController:(UIViewController *)viewController
{
    _vc = viewController;
    _networkId = networkId;

    // network initialization code goes here

    // you need to call networkLoaded when you're done initializing the ad network
    // this lets buildbox know that it is safe to request ads from the network
    //    [self networkLoaded];
    
    // REMOVE THE FOLLOWING TWO LINES
    NSLog(@"[CustomAdIntegrator initAdNetwork] Custom ad integrator needs to be implemented!");
    [self networkFailed];
}

/**
 * Load a banner. If banner is one time use, then initialize a new one before loading.
 */
- (void)initBanner {
    NSLog(@"[CustomAdIntegrator initBanner");
}

/**
 * Load an interstitial ad.
 */
- (void)initInterstitial {
    NSLog(@"[CustomAdIntegrator initInterstitial");
}

/**
 * Load a rewarded video.
 */
- (void)initRewardedVideo {
    NSLog(@"[CustomAdIntegrator initRewardedVideo");
}

/**
 * Show a banner.
 */
- (void)showBanner{
    NSLog(@"[CustomAdIntegrator showBanner");
    // TODO - Call the below method when a banner ad is successfully shown to the user
    [AdIntegratorInterface bannerImpression:[NSString stringWithFormat:@"%@ - %@", _networkId, CustomNetworkName]];
}

/**
 * Hide the banner.
 */
- (void)hideBanner{
    NSLog(@"[CustomAdIntegrator hideBanner");
    
    // ex: [_bannerView setHidden:YES];
}

/**
 * Show an interstitial
 */
- (void)showInterstitial {
    NSLog(@"[CustomAdIntegrator showInterstitial");
    // TODO - Call the below method when an interstitial ad is successfully shown to the user
    [AdIntegratorInterface interstitialImpression:[NSString stringWithFormat:@"%@ - %@", _networkId, CustomNetworkName]];
}
/**
 * Show a rewarded video
 */
- (void)showRewardedVideo {
    NSLog(@"[CustomAdIntegrator showRewardedVideo");
    // TODO - Call the below method when a rewarded video ad is successfully shown to the user
    [AdIntegratorInterface rewardedVideoImpression:[NSString stringWithFormat:@"%@ - %@", _networkId, CustomNetworkName]];
}

/**
 * @return true if the banner is currently visible
 */
- (bool)isBannerVisible {
    // ex: return [_bannerView isHidden];
    return false;
}
/**
 * @return true if a rewarded video is loaded and ready to show
 */
- (bool)isRewardedVideoAvailable {
    return false;
}

#pragma mark Call these methods when appropriate (i.e. call interstitialLoaded when an interstitial is ready to be played.)

/*
 Call this when you are done configuring the ad network.
 (i.e. at the end of initAdNetwork)
 */
- (void)networkLoaded {
    [AdIntegratorInterface networkLoaded:_networkId];
}

/*
 Call this if you are unable to configure the ad network. Buildbox will stop
 trying to run methods in the integrator after you call this.
*/
- (void)networkFailed {
    [AdIntegratorInterface networkFailed:_networkId];
}

/*
 Call this when the ad network reports that it is ready to display an interstitial ad
*/
- (void)interstitialLoaded {
    [AdIntegratorInterface interstitialLoaded:_networkId];
}

/*
 Call this when the ad network reports an impression for an interstitial ad
*/
- (void)interstitialImpression {
    [AdIntegratorInterface interstitialImpression:_networkId];
}

/*
 Call this if an interstitial ad failed to load or be displayed
*/
- (void)interstitialFailed {
    [AdIntegratorInterface interstitialFailed:_networkId];
}

/*
 Call this after the interstitial ad was cloased
*/
- (void)interstitialClosed {
    [AdIntegratorInterface interstitialClosed:_networkId];
}

/*
 Call this when the ad network reports that it is ready to display a banner ad
*/
- (void)bannerLoaded {
    [AdIntegratorInterface bannerLoaded:_networkId];
}

/*
 Call this when the ad network reports an impression for a banner ad
*/
- (void)bannerImpression {
    [AdIntegratorInterface bannerImpression:_networkId];
}

/*
 Call this if a banner ad failed to load or be displayed
*/
- (void)bannerFailed {
    [AdIntegratorInterface bannerFailed:_networkId];
}

/*
 Call this when the ad network reports that it is ready to display a rewarded video
*/
- (void)rewardedVideoLoaded {
    [AdIntegratorInterface rewardedVideoLoaded:_networkId];
}

/*
 Call this if a rewarded video failed to load or be displayed
*/
- (void)rewardedVideoFailed {
    [AdIntegratorInterface rewardedVideoFailed:_networkId];
}

/*
 Call this if the ad network reported the view received an award (i.e. the watched the entire rewarded video)
*/
- (void)rewardedVideoDidReward {
    [AdIntegratorInterface rewardedVideoDidReward:_networkId];
}

/*
 Call this after the rewarded video was cloased
*/
- (void)rewardedVideoDidEnd {
    [AdIntegratorInterface rewardedVideoDidEnd:_networkId];
}

@end

