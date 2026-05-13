#import <Foundation/Foundation.h>
//
//  AdIntegrator.h
//  IronSourceAdIntegrator
//
//  Created by Cody Thompson on 11/13/19.
//  Copyright © 2019 Buildbox. All rights reserved.
//

@interface CustomAdIntegrator : NSObject {
    UIViewController* _vc;
    NSString* _networkId;
}

+ (id)shared;

- (void)setConsent:(bool)consented;
- (void)initAdNetwork:(NSString*)networkId
   withViewController:(UIViewController*)viewController;

- (void)initInterstitial;
- (void)showInterstitial;

- (void)initRewardedVideo;
- (void)showRewardedVideo;
- (bool)isRewardedVideoAvailable;

- (void)initBanner;
- (void)showBanner;
- (void)hideBanner;
- (bool)isBannerVisible;

@end

