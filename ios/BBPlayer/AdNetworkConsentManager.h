//
//  NetworkConsentInformationManager.h
//  BBPlayer
//
//  Created by armen on 11/20/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define CONSENT_SHOWN_KEY @"CONSENTSHOWKEY"


@class AdNetworkConsentInformation;
@class UIViewController;

@protocol AdNetworkConsentManagerDownloadDelegate <NSObject>
-(void)networkInfoCompletedDownload;
@end

@interface AdNetworkConsentManager : NSObject

+(AdNetworkConsentManager*)sharedManager;
-(void)consentToAllNetworksAccepted;
-(void)consentToAllNetworksDeclined;
-(void)usePerNetworkConsentSettingForAll;

-(void)presentConsentDialogWithViewController:(UIViewController*)rootVC;

-(bool)getConsentStatusForNetworkWithName:(NSString*)networkName;

-(void)setupAdNetworks;

@property (nonatomic, weak) id <AdNetworkConsentManagerDownloadDelegate> downloadDelegate;
@property (strong, nonatomic) NSMutableArray<AdNetworkConsentInformation*> *networkConsentInfoArray;
@property (strong, atomic) NSMutableArray *installedNetworks;
@end

NS_ASSUME_NONNULL_END
